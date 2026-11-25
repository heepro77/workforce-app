-- ============================================================
-- 인력관리 앱 (heepro77/workforce-app) · Supabase 스키마
-- Supabase 대시보드 → SQL Editor 에 붙여넣고 Run 하세요.
-- 여러 번 실행해도 안전합니다(if not exists / drop policy if exists).
-- ============================================================

create table if not exists public.wf_workers (
  id text primary key,
  name text,
  phone text,
  status text,
  hourly_rate integer,
  bank text,
  age integer,
  age_group text,
  personality text,
  looks text,
  memo text,
  created_at timestamptz default now()
);

-- 인력 연령대 구분 (20대 · 생초 · 어생 · 생점 · 젊초 · 젊은점)
alter table public.wf_workers add column if not exists age_group text;

create table if not exists public.wf_clients (
  id text primary key,
  name text,
  manager text,
  phone text,
  address text,
  memo text,
  created_at timestamptz default now()
);

create table if not exists public.wf_logs (
  id text primary key,
  worker_id text,
  worker_name text,
  date text,
  start_time text,
  end_time text,
  hours numeric,
  hourly_rate integer,
  pay integer,
  allowance integer default 0,
  allowance_memo text,
  pay_manual boolean default false,
  client_id text,
  place text,
  memo text,
  client_paid boolean default false,
  client_paid_date text,
  client_paid_by text,
  worker_paid boolean default false,
  worker_paid_date text,
  worker_paid_by text,
  created_by text,
  created_at timestamptz default now()
);

-- ON/OFF 를 누른 실제 시각 (이미 만든 표에도 칸을 더한다)
alter table public.wf_logs add column if not exists on_at text;
alter table public.wf_logs add column if not exists off_at text;

-- 근무시간 외 추가 수당 (일당 = 근무시간 × 시급 + 수당)
alter table public.wf_logs add column if not exists allowance integer default 0;
alter table public.wf_logs add column if not exists allowance_memo text;

-- 기록을 마지막으로 고친 관리자 (created_by = 처음 기록한 관리자)
alter table public.wf_logs add column if not exists updated_by text;
alter table public.wf_logs add column if not exists updated_at timestamptz;

create table if not exists public.wf_sms (
  id text primary key,
  mode text,
  recipients text[],
  count integer,
  body text,
  sent_by text,
  sent_at text,
  created_at timestamptz default now()
);

create table if not exists public.wf_expenses (
  id text primary key,
  date text,
  category text,
  amount integer,
  memo text,
  created_by text,
  created_at timestamptz default now()
);

alter table public.wf_expenses add column if not exists updated_by text;

-- ------------------------------------------------------------
-- 관리자 계정: 이름·역할·비밀번호 해시 (관리자 3명 기기에서 함께 쓴다)
-- 비밀번호는 앱에서 SHA-256 해시로만 넣는다. 평문은 저장하지 않는다.
-- ------------------------------------------------------------
create table if not exists public.wf_admins (
  id text primary key,
  name text,
  role text,
  pass_hash text,
  updated_by text,
  updated_at timestamptz default now()
);

create table if not exists public.wf_messages (
  id text primary key,
  sender text,
  body text,
  tag text,
  created_at timestamptz default now()
);

-- ------------------------------------------------------------
-- 실시간 반영: 5개 테이블을 supabase_realtime publication 에 등록
-- ------------------------------------------------------------
do $$
declare
  t text;
begin
  foreach t in array array['wf_workers', 'wf_clients', 'wf_logs', 'wf_sms', 'wf_messages', 'wf_expenses', 'wf_admins']
  loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

-- ------------------------------------------------------------
-- 접근 권한: 공개 페이지에서 publishable(anon) 키로 읽고 쓰기
-- (사내 데모용 설정입니다. 실제 개인정보는 넣지 마세요.)
-- ------------------------------------------------------------
alter table public.wf_workers  enable row level security;
alter table public.wf_clients  enable row level security;
alter table public.wf_logs     enable row level security;
alter table public.wf_sms      enable row level security;
alter table public.wf_messages enable row level security;
alter table public.wf_expenses enable row level security;
alter table public.wf_admins   enable row level security;

drop policy if exists wf_anon_all on public.wf_workers;
create policy wf_anon_all on public.wf_workers  for all to anon, authenticated using (true) with check (true);

drop policy if exists wf_anon_all on public.wf_clients;
create policy wf_anon_all on public.wf_clients  for all to anon, authenticated using (true) with check (true);

drop policy if exists wf_anon_all on public.wf_logs;
create policy wf_anon_all on public.wf_logs     for all to anon, authenticated using (true) with check (true);

drop policy if exists wf_anon_all on public.wf_sms;
create policy wf_anon_all on public.wf_sms      for all to anon, authenticated using (true) with check (true);

drop policy if exists wf_anon_all on public.wf_messages;
create policy wf_anon_all on public.wf_messages for all to anon, authenticated using (true) with check (true);

drop policy if exists wf_anon_all on public.wf_expenses;
create policy wf_anon_all on public.wf_expenses for all to anon, authenticated using (true) with check (true);

drop policy if exists wf_anon_all on public.wf_admins;
create policy wf_anon_all on public.wf_admins   for all to anon, authenticated using (true) with check (true);

grant select, insert, update, delete on
  public.wf_workers, public.wf_clients, public.wf_logs, public.wf_sms, public.wf_messages, public.wf_expenses,
  public.wf_admins
  to anon, authenticated;
