-- Run once in Supabase Dashboard > SQL Editor.
-- Orders stay private: the browser can only look up ONE order by its exact order ID via track_order().

create table if not exists public.orders (
  id          bigint generated always as identity primary key,
  order_ref   text unique not null,          -- e.g. 'ME1001' (what the customer types)
  status      text not null default 'Order placed',
  items       text,
  eta         date,
  updated_at  timestamptz not null default now()
);

alter table public.orders enable row level security;   -- no policies = anon cannot read the table directly

create or replace function public.track_order(p_ref text)
returns table (order_ref text, status text, items text, eta date, updated_at timestamptz)
language sql
security definer
set search_path = public
as $$
  select o.order_ref, o.status, o.items, o.eta, o.updated_at
  from public.orders o
  where upper(o.order_ref) = upper(trim(p_ref))
  limit 1;
$$;

revoke all on function public.track_order(text) from public;
grant execute on function public.track_order(text) to anon, authenticated;

-- Sample order to test with:
insert into public.orders (order_ref, status, items, eta)
values ('ME1001', 'Out for delivery', 'Onion Hair Oil x1, Vitamin C Serum x1', current_date + 1)
on conflict (order_ref) do nothing;
