-- LigaLab WEB v6.2 · Ejecutar UNA VEZ en Supabase > SQL Editor.
-- Crea un estado oficial público de solo lectura y una lista privada de administradores.

create table if not exists public.ligalab_state (
  id text primary key,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid null references auth.users(id) on delete set null
);

create table if not exists public.ligalab_signal (
  id text primary key,
  version bigint not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists public.ligalab_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

insert into public.ligalab_state (id, payload)
values ('main', '{}'::jsonb)
on conflict (id) do nothing;

insert into public.ligalab_signal (id, version)
values ('main', 0)
on conflict (id) do nothing;

alter table public.ligalab_state enable row level security;
alter table public.ligalab_signal enable row level security;
alter table public.ligalab_admins enable row level security;

-- Privilegios mínimos para la API del navegador. RLS decide qué filas puede tocar cada rol.
revoke all on public.ligalab_state from anon, authenticated;
revoke all on public.ligalab_signal from anon, authenticated;
revoke all on public.ligalab_admins from anon, authenticated;
grant select on public.ligalab_state to anon, authenticated;
grant select on public.ligalab_signal to anon, authenticated;
grant update on public.ligalab_state to authenticated;
grant update on public.ligalab_signal to authenticated;
grant select on public.ligalab_admins to authenticated;

drop policy if exists "public read ligalab state" on public.ligalab_state;
create policy "public read ligalab state"
on public.ligalab_state for select
to anon, authenticated
using (id = 'main');

drop policy if exists "admins update ligalab state" on public.ligalab_state;
create policy "admins update ligalab state"
on public.ligalab_state for update
to authenticated
using (exists (select 1 from public.ligalab_admins a where a.user_id = auth.uid()))
with check (exists (select 1 from public.ligalab_admins a where a.user_id = auth.uid()));

drop policy if exists "public read ligalab signal" on public.ligalab_signal;
create policy "public read ligalab signal"
on public.ligalab_signal for select
to anon, authenticated
using (id = 'main');

drop policy if exists "admins update ligalab signal" on public.ligalab_signal;
create policy "admins update ligalab signal"
on public.ligalab_signal for update
to authenticated
using (exists (select 1 from public.ligalab_admins a where a.user_id = auth.uid()))
with check (exists (select 1 from public.ligalab_admins a where a.user_id = auth.uid()));

drop policy if exists "admin can see own grant" on public.ligalab_admins;
create policy "admin can see own grant"
on public.ligalab_admins for select
to authenticated
using (user_id = auth.uid());

-- Realtime: publica solo la señal pequeña. Cuando cambia, los visitantes vuelven a leer el estado oficial.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'ligalab_signal'
  ) then
    alter publication supabase_realtime add table public.ligalab_signal;
  end if;
end $$;

-- IMPORTANTE:
-- 1) Después crea TU usuario en Authentication > Users.
-- 2) Copia su UUID y ejecuta, reemplazando TU_UUID:
--    insert into public.ligalab_admins(user_id) values ('TU_UUID') on conflict do nothing;
-- Solo los UUID presentes en ligalab_admins pueden modificar el estado oficial.
