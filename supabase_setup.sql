-- ==============================================================================
-- MyFinance Supabase Database Schema & Row Level Security Policies
-- ==============================================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. Accounts Table
create table if not exists public.accounts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  type text not null,
  institution_name text not null,
  currency text default 'LKR' not null,
  opening_balance bigint default 0 not null,
  current_balance bigint default 0 not null,
  is_archived boolean default false not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.accounts enable row level security;

create policy "Users can only access their own accounts"
  on public.accounts for all
  using (auth.uid() = user_id);

-- 2. Transactions Table
create table if not exists public.transactions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade not null,
  type text not null,
  amount bigint not null,
  source_account_id uuid references public.accounts(id) on delete set null,
  destination_account_id uuid references public.accounts(id) on delete set null,
  category_id text,
  sub_category_id text,
  transaction_date timestamp with time zone not null,
  description text not null,
  notes text,
  status text default 'completed' not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.transactions enable row level security;

create policy "Users can only access their own transactions"
  on public.transactions for all
  using (auth.uid() = user_id);

-- 3. Categories Table (Custom Categories)
create table if not exists public.categories (
  id text primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  type text not null,
  icon_code text default 'category',
  color_value bigint default 1113985,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.categories enable row level security;

create policy "Users can only access their own categories"
  on public.categories for all
  using (auth.uid() = user_id);
