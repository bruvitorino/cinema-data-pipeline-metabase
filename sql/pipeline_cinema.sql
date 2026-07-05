-- ==========================================
-- 1. CAMADA SILVER: MODELAGEM DIMENSIONAL
-- ==========================================

CREATE OR REPLACE TABLE silver_cinema.dim_movies AS
SELECT
  SAFE_CAST(movie_id AS INT64) AS movie_id,
  TRIM(title) AS title,
  TRIM(genres) AS genres,
  -- Extrai o ano de lançamento de dentro dos parênteses do título, se houver
  SAFE_CAST(REGEXP_EXTRACT(title, r'\((\d{4})\)') AS INT64) AS release_year
FROM
  belief_data.movie_elicitation_set; -- Sua tabela raw de filmes

-- ==========================================
-- 2. CAMADA SILVER: MODELAGEM FATOS
-- ==========================================

CREATE OR REPLACE TABLE silver_cinema.fact_ratings AS
SELECT
  SAFE_CAST(user_id AS INT64) AS user_id,
  SAFE_CAST(movie_id AS INT64) AS movie_id,
  SAFE_CAST(rating AS FLOAT64) AS rating,
  -- Faz o parse do timestamp Unix para o formato de DATA/HORA real
  TIMESTAMP_SECONDS(SAFE_CAST(timestamp AS INT64)) AS rating_timestamp
FROM
  belief_data.fact_ratings_raw; -- Sua tabela raw de ratings

-- ==========================================
-- 3. CAMADA GOLD: VIEWS ANALÍTICAS
-- ==========================================

-- ==========================================
-- vw_genre_performance
-- ==========================================
CREATE OR REPLACE VIEW silver_cinema.vw_genre_performance AS
SELECT
  m.genres,
  -- Calculando a média de nota para o gênero como um todo
  ROUND(AVG(r.rating), 2) AS rating_medio_genero,
  -- Volume total de votos que este gênero recebeu
  COUNT(r.movie_id) AS total_avaliacoes_genero,
  -- Quantidade de filmes diferentes que pertencem a este gênero
  COUNT(DISTINCT m.movie_id) AS total_filmes_genero
FROM
  `silver_cinema.dim_movies` m
INNER JOIN
  `silver_cinema.fact_ratings` r ON m.movie_id = r.movie_id
WHERE
  r.rating >= 0
GROUP BY
  m.genres
ORDER BY
  total_avaliacoes_genero DESC;

-- ==========================================
-- vw_movie_kpis
-- ==========================================
CREATE OR REPLACE VIEW silver_cinema.vw_movie_kpis AS
SELECT
  m.movie_id,
  m.title,
  m.release_year,
  m.genres,
  ROUND(AVG(CASE WHEN r.rating >= 0 THEN r.rating END), 2) AS rating_medio,
  COUNT(CASE WHEN r.rating >= 0 THEN 1 END) AS total_avaliacoes
FROM
  `silver_cinema.dim_movies` m
INNER JOIN
  `silver_cinema.fact_ratings` r ON m.movie_id = r.movie_id
WHERE 
  r.rating >= 0
GROUP BY
  m.movie_id, m.title, m.release_year, m.genres;

-- ==========================================
-- vw_ratings_heatmap
-- ==========================================
CREATE OR REPLACE VIEW silver_cinema.vw_ratings_heatmap AS
SELECT
  -- Extrai a hora (0 a 23)
  EXTRACT(HOUR FROM rating_timestamp) AS hora_do_dia,
  
  -- Extrai o número do dia da semana (1 a 7) para ordenação correta
  EXTRACT(DAYOFWEEK FROM rating_timestamp) AS dia_da_semana_num,
  
  -- Traduz o número para o nome do dia abreviado
  CASE EXTRACT(DAYOFWEEK FROM rating_timestamp)
    WHEN 1 THEN 'Dom'
    WHEN 2 THEN 'Seg'
    WHEN 3 THEN 'Ter'
    WHEN 4 THEN 'Qua'
    WHEN 5 THEN 'Qui'
    WHEN 6 THEN 'Sex'
    WHEN 7 THEN 'Sáb'
  END AS dia_da_semana,
  
  -- Conta quantas avaliações aconteceram naquele cruzamento de hora e dia
  COUNT(*) AS total_avaliacoes
FROM
  `silver_cinema.fact_ratings`
WHERE
  -- Mantemos o nosso filtro de segurança para ignorar as notas inválidas (-1)
  rating >= 0
GROUP BY
  hora_do_dia,
  dia_da_semana_num,
  dia_da_semana;

-- ==========================================
-- vw_scatter_popularity_vs_quality
-- ==========================================  
CREATE OR REPLACE VIEW silver_cinema.vw_scatter_popularity_vs_quality AS
SELECT
  movie_id,
  title,
  release_year,
  genres,
  -- Total de avaliações servirá como o nosso Eixo X (Popularidade)
  total_avaliacoes AS popularidade_eixo_x,
  -- A nota média servirá como o nosso Eixo Y (Qualidade)
  rating_medio AS qualidade_eixo_y
FROM
  `silver_cinema.vw_movie_kpis`;

-- ==========================================
-- vw_user_activity
-- ==========================================
CREATE OR REPLACE VIEW silver_cinema.vw_user_activity AS
SELECT
  user_id,
  -- Contando o total de críticas que este usuário específico fez
  COUNT(*) AS total_avaliacoes_usuario,
  -- Calculando a nota média que este usuário costuma dar
  ROUND(AVG(rating), 2) AS rating_medio_usuario,
  -- Identificando a data da primeira e da última avaliação dele na plataforma
  MIN(rating_timestamp) AS primeira_avaliacao,
  MAX(rating_timestamp) AS ultima_avaliacao
FROM
  `silver_cinema.fact_ratings`
WHERE
  -- Mantendo o nosso filtro padrão para ignorar notas inválidas
  rating >= 0
GROUP BY
  user_id;
