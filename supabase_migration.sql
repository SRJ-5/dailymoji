-- create table if not exists sessions (
--   id uuid primary key default gen_random_uuid(),
--   created_at timestamptz default now(),
--   text text,
--   profile int,
--   g_score float,
--   intervention jsonb,
--   debug_log jsonb
-- );

-- create table if not exists cluster_scores (
--   id uuid primary key default gen_random_uuid(),
--   created_at timestamptz default now(),
--   cluster text,
--   score float,
--   session_text text
-- );

-- alter table sessions enable row level security;
-- alter table cluster_scores enable row level security;

-- create policy "anon_read_sessions" on sessions for select using (true);
-- create policy "anon_insert_sessions" on sessions for insert with check (true);

-- create policy "anon_read_cluster_scores" on cluster_scores for select using (true);
-- create policy "anon_insert_cluster_scores" on cluster_scores for insert with check (true);
