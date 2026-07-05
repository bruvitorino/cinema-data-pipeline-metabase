# 🎬 Cinema Data Pipeline & Analytics (MovieLens 2024)

Este projeto apresenta uma solução completa de Engenharia de Dados e Analytics ponta a ponta. A arquitetura foi desenhada para realizar a ingestão, armazenamento, modelagem estruturada e visualização analítica de dados cinematográficos.

## 🛠️ Tecnologias Utilizadas
* **Armazenamento & Data Warehouse:** Google Cloud Storage (GCS) & Google BigQuery
* **Infraestrutura:** Docker & Containers (Metabase)
* **Visualização de Dados:** Metabase
* **Linguagem Principal:** SQL Avançado

---

## 🏗️ Arquitetura do Pipeline (Passo a Passo)

### 📁 1. Ingestão e Camada Bronze (Raw)
* **Passo 1 (Dataset):** Utilização do dataset público MovieLens (https://grouplens.org/datasets/movielens/ml_belief_2024/) focado em comportamento cinematográfico.
* **Passo 2 (Cloud Storage):** Criação de um bucket no Google Cloud Storage (GCS) estruturado com a pasta `/bronze` para armazenamento dos arquivos CSV originais de filmes e avaliações.
* **Passo 3 (Tabelas Externas):** Configuração de um dataset raw no Google BigQuery apontando tabelas externas diretamente para o GCS. Todas as colunas foram tipadas inicialmente como `STRING` para evitar quebras por valores nulos (`NA`) ou problemas de formatação.

### 🗄️ 2. Modelagem e Camada Silver (Analytics)
* **Passo 4.1 (Dimensão Filmes):** Criação da tabela estruturada `dim_movies` no BigQuery, limpando strings e utilizando Expressões Regulares (`REGEXP_EXTRACT`) para extrair de forma isolada o ano de lançamento dos títulos.
* **Passo 4.2 (Fato Avaliações):** Criação da tabela `fact_ratings`, limpando notas inválidas e convertendo timestamps Unix nativos para o formato real de data e hora (`TIMESTAMP_SECONDS`).

### ⚙️ 3. Camada Gold (Views Analíticas)
* **Passo 5 (Views Otimizadas):** Construção das Views analíticas de consumo para blindar a performance do banco de dados e entregar dados pré-agregados:
  * `vw_movie_kpis` (Métricas centrais de performance de filmes)
  * `vw_top_movies` (Ranking dos 10 melhores títulos)
  * `vw_ratings_heatmap` (Agrupamento temporal por dia e hora)
  * `vw_scatter_popularity_vs_quality` (Mapeamento de eixos X e Y)
  * `vw_user_activity` (Métricas consolidadas de comportamento por usuário)
  * `vw_genre_performance` (Desempenho por categoria)
* **Passo 6 (Mapeamento de Regras):** Definição das regras analíticas e filtros de segurança (ignorar notas negativas) direto na camada de banco.

### 🐳 4. Infraestrutura e Conexão Segura (IAM)
* **Passo 7 (Docker Container):** Inicialização e provisionamento do servidor local do Metabase via container utilizando Docker para isolamento e facilidade de deploy.
  - docker run -d -p 3000:3000 --name metabase metabase/metabase
  - Acessar:
  - http://localhost:3000
* **Passo 8 (Políticas de IAM):** Integração segura entre o Metabase e a Google Cloud Platform (GCP) através de chaves de uma Service Account (JSON), respeitando as boas práticas de privilégio mínimo com as permissões:
  * *BigQuery Data Viewer*
  * *BigQuery Job User*
  * *BigQuery Metadata Viewer*

### 📊 5. Analytics e Entrega no Metabase
* **Passo 9 (Sincronização de Metadados):** Execução do processo de *Sync database schema* para atualizar os metadados e carregar de forma instantânea as Views estruturadas no Metabase.
* **Passo 10 (Construção das Questions):** Criação das queries visuais utilizando agregações refinadas de cruzamento de eixos.
* **Passo 11 (Montagem do Dashboard):** Consolidação dos gráficos em um Dashboard unificado e profissional, com destaque para o **Gráfico de Dispersão** (Popularidade vs Qualidade) e o **Mapa de Calor Temporal** com formatação condicional em degradê para análise de picos de engajamento dos usuários.

---

## 💾 Scripts SQL Principais
Todo o código de criação das tabelas Fato, Dimensão e das Views Analíticas do BigQuery foi centralizado e documentado na pasta de scripts do repositório.
* 📄 [Clique aqui para acessar as queries do projeto](sql/pipeline_cinema.sql)

---

## 📊 Entrega Final: Dashboard Analítico
Abaixo está a consolidação visual das métricas extraídas do Data Warehouse e renderizadas no Metabase:

### 🗺️ Mapa de Calor Temporal (Heatmap)
Matriz de engajamento que cruza a hora do dia com os dias da semana, evidenciando o comportamento da audiência e picos de acessos na plataforma.

![Mapa de Calor](003.jpg)

### 📈 Gráfico de Dispersão (Scatter Plot)
Análise correlacionando o volume total de votos (Eixo X / Popularidade) com a nota média dos usuários (Eixo Y / Qualidade) para identificar a percepção de qualidade de grandes blockbusters versus filmes cult.

![Gráfico de Dispersão](006.jpg)

### 🖥️ Dashboard Consolidado (Visão Geral)
Visualização unificada do painel gerencial final entregue no Metabase acessível localmente.

*(Apague essa linha e arraste o print do dashboard completo aqui)*
