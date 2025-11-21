CREATE EXTENSION IF NOT EXISTS pgcrypto;

DROP TYPE IF EXISTS transaction_type CASCADE;
CREATE TYPE transaction_type AS ENUM (
  'cash_in',
  'cash_out',
  'fare_payment',
  'token_redemption',
  'driver_payout',
  'operator_payout'
);

CREATE TYPE user_role AS ENUM ('admin','commuter','driver','operator');
CREATE TYPE commuter_category AS ENUM ('regular','senior','student','pwd');
CREATE TYPE report_category AS ENUM ('vehicle','driver','traffic','lost_item','safety_security','app','miscellaneous','route');
CREATE TYPE report_status AS ENUM ('open','in_review','resolved','dismissed','closed');
CREATE TYPE report_severity AS ENUM ('low','medium','high');
CREATE TYPE trip_status AS ENUM ('ongoing','completed','cancelled');
CREATE TYPE transaction_status AS ENUM ('pending','completed','failed');
CREATE TYPE notification_type AS ENUM ('trip','wallet','rewards','verification','report','system');
CREATE TYPE verification_status AS ENUM ('pending','approved','rejected','lacking');

CREATE OR REPLACE FUNCTION komyut_update_timestamp()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid UNIQUE, 
  role user_role NOT NULL,
  first_name text NOT NULL,
  last_name text NOT NULL,
  dob date,
  age integer,
  sex varchar(16),
  phone text,
  address text,
  is_verified boolean DEFAULT false,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE profiles
  ADD CONSTRAINT fk_profiles_auth_user
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE INDEX idx_profiles_role ON profiles(role);

CREATE TRIGGER trg_profiles_updated_at
BEFORE UPDATE ON profiles
FOR EACH ROW
EXECUTE FUNCTION komyut_update_timestamp();

CREATE TABLE attachments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_profile_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  bucket text,
  path text,
  url text,
  content_type text,
  size_bytes bigint,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX idx_attachments_owner ON attachments(owner_profile_id);

CREATE TABLE operators (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,
  company_name text,
  company_address text,
  contact_email text,
  contact_phone text,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
CREATE TRIGGER trg_operators_updated_at
BEFORE UPDATE ON operators
FOR EACH ROW
EXECUTE FUNCTION komyut_update_timestamp();

CREATE TABLE drivers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,
  license_number text NOT NULL,
  license_image_url text,
  status boolean DEFAULT false,
  operator_id uuid REFERENCES operators(id) ON DELETE SET NULL,
  operator_name text, 
  current_qr text UNIQUE, 
  vehicle_plate text,
  route_code text,
  puv_type text,
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
CREATE TRIGGER trg_drivers_updated_at
BEFORE UPDATE ON drivers
FOR EACH ROW
EXECUTE FUNCTION komyut_update_timestamp();

CREATE INDEX idx_drivers_operator ON drivers(operator_id);

CREATE TABLE commuters (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,
  category commuter_category NOT NULL DEFAULT 'regular',
  attachment_id uuid REFERENCES attachments(id) ON DELETE SET NULL,
  id_verified boolean DEFAULT false,
  wheel_tokens numeric(10, 2) DEFAULT 0 CHECK (wheel_tokens >= 0),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
CREATE TRIGGER trg_commuters_updated_at
BEFORE UPDATE ON commuters
FOR EACH ROW
EXECUTE FUNCTION komyut_update_timestamp();

CREATE TABLE routes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text UNIQUE NOT NULL, 
  name text,
  description text,
  start_lat numeric(10,6),
  start_lng numeric(10,6),
  end_lat numeric(10,6),
  end_lng numeric(10,6),
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
CREATE TRIGGER trg_routes_updated_at
BEFORE UPDATE ON routes
FOR EACH ROW
EXECUTE FUNCTION komyut_update_timestamp();

CREATE TABLE route_stops (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id uuid REFERENCES routes(id) ON DELETE CASCADE,
  name text NOT NULL,
  sequence integer NOT NULL,
  latitude numeric(10,6),
  longitude numeric(10,6),
  created_at timestamptz DEFAULT now()
);
CREATE INDEX idx_route_stops_route_seq ON route_stops(route_id, sequence);

CREATE TABLE trips (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id uuid REFERENCES drivers(id) ON DELETE SET NULL,
  route_id uuid REFERENCES routes(id) ON DELETE SET NULL,
  origin_stop_id uuid REFERENCES route_stops(id) ON DELETE SET NULL,
  destination_stop_id uuid REFERENCES route_stops(id) ON DELETE SET NULL,
  distance_meters integer CHECK (distance_meters >= 0),
  fare_amount numeric(12,2) CHECK (fare_amount >= 0),
  passengers_count integer DEFAULT 1 CHECK (passengers_count >= 1),
  status trip_status NOT NULL DEFAULT 'ongoing',
  started_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz,
  created_by_profile_id uuid REFERENCES profiles(id) NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  metadata jsonb DEFAULT '{}'::jsonb
);

CREATE TRIGGER trg_trips_updated_at
BEFORE UPDATE ON trips
FOR EACH ROW
EXECUTE FUNCTION komyut_update_timestamp();

-- Wallets
CREATE TABLE wallets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_profile_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  balance numeric(14,2) DEFAULT 0 CHECK (balance >= 0),
  locked boolean DEFAULT false,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
CREATE UNIQUE INDEX uq_wallet_owner ON wallets(owner_profile_id);
CREATE TRIGGER trg_wallets_updated_at
BEFORE UPDATE ON wallets
FOR EACH ROW
EXECUTE FUNCTION komyut_update_timestamp();

CREATE TABLE transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_number text UNIQUE,
  wallet_id uuid REFERENCES wallets(id) ON DELETE SET NULL,
  initiated_by_profile_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  type transaction_type NOT NULL,
  amount numeric(14,2) NOT NULL CHECK (amount >= 0),
  fee numeric(14,2) DEFAULT 0 CHECK (fee >= 0),
  status transaction_status DEFAULT 'pending',
  related_trip_id uuid REFERENCES trips(id) ON DELETE SET NULL,
  external_reference text, 
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  processed_at timestamptz
);


CREATE TABLE trip_participants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id uuid REFERENCES trips(id) ON DELETE CASCADE,
  commuter_id uuid REFERENCES commuters(id) ON DELETE SET NULL,
  payer_profile_id uuid REFERENCES profiles(id) NOT NULL,
  passenger_count integer DEFAULT 1 CHECK(passenger_count >= 1),
  fare_per_person numeric(12,2) CHECK (fare_per_person >= 0),
  transaction_id uuid REFERENCES transactions(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX idx_trip_participants_trip ON trip_participants(trip_id);

CREATE UNIQUE INDEX uq_commuter_ongoing_trip
ON trips(created_by_profile_id)
WHERE status = 'ongoing';


CREATE TABLE points_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  commuter_id uuid REFERENCES commuters(id) ON DELETE CASCADE,
  change numeric(10, 2) NOT NULL, 
  reason text,
  related_transaction_id uuid REFERENCES transactions(id) ON DELETE SET NULL,
  balance_after numeric(10, 2),
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX idx_points_commuter ON points_transactions(commuter_id);

CREATE TABLE ratings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id uuid REFERENCES trips(id) ON DELETE CASCADE,
  commuter_id uuid REFERENCES commuters(id) ON DELETE SET NULL,
  driver_id uuid REFERENCES drivers(id) ON DELETE SET NULL,
  courtesy smallint CHECK (courtesy BETWEEN 1 AND 5),
  safety smallint CHECK (safety BETWEEN 1 AND 5),
  vehicle_condition smallint CHECK (vehicle_condition BETWEEN 1 AND 5),
  overall smallint CHECK (overall BETWEEN 1 AND 5),
  app_experience smallint CHECK (app_experience BETWEEN 1 AND 5),
  comment text,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX idx_ratings_driver ON ratings(driver_id);

CREATE TABLE reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_profile_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  reported_entity_type text,
  reported_entity_id uuid,
  category report_category,
  severity report_severity,
  status report_status DEFAULT 'open',
  description text,
  attachment_id uuid REFERENCES attachments(id) ON DELETE SET NULL,
  assigned_to_profile_id uuid REFERENCES profiles(id) ON DELETE SET NULL, 
  resolution_notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
CREATE INDEX idx_reports_status ON reports(status);
CREATE TRIGGER trg_reports_updated_at
BEFORE UPDATE ON reports
FOR EACH ROW
EXECUTE FUNCTION komyut_update_timestamp();

CREATE TABLE notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  type notification_type,
  title text,
  message text,
  payload jsonb DEFAULT '{}'::jsonb,
  read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX idx_notifications_recipient ON notifications(recipient_profile_id, read);

CREATE TABLE verifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  verification_type text, 
  attachment_id uuid REFERENCES attachments(id) ON DELETE SET NULL,
  status verification_status DEFAULT 'pending',
  reviewer_profile_id uuid REFERENCES profiles(id),
  reviewer_notes text,
  created_at timestamptz DEFAULT now(),
  reviewed_at timestamptz
);

CREATE TABLE fare_policies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text,
  description text,
  base_fare numeric(12,2) DEFAULT 0,
  per_km numeric(12,2) DEFAULT 0,
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE fare_brackets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  fare_policy_id uuid REFERENCES fare_policies(id) ON DELETE CASCADE,
  min_distance integer NOT NULL,
  max_distance integer NOT NULL,
  price numeric(12,2) NOT NULL
);
CREATE INDEX idx_fare_brackets_policy ON fare_brackets(fare_policy_id);

CREATE TABLE audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_profile_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  action text,
  target_table text,
  target_id uuid,
  details jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now()
);

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_driver_revenue AS
SELECT
  d.id AS driver_id,
  (p.first_name || ' ' || p.last_name) AS driver_name,
  SUM(t.amount) FILTER (WHERE t.type = 'fare_payment' AND t.status='completed') AS total_fares,
  COUNT(DISTINCT tr.id) AS total_trips
FROM drivers d
LEFT JOIN profiles p ON p.id = d.profile_id
LEFT JOIN trips tr ON tr.driver_id = d.id
LEFT JOIN transactions t ON t.related_trip_id = tr.id
GROUP BY d.id, p.first_name, p.last_name;

ALTER TABLE drivers 
ADD COLUMN route_id uuid REFERENCES routes(id) ON DELETE SET NULL;

-- Migrate existing data
UPDATE drivers d
SET route_id = r.id
FROM routes r
WHERE d.route_code = r.code;

-- Add index
CREATE INDEX idx_drivers_route ON drivers(route_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_trips_driver_started_at ON trips(driver_id, started_at);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_verifications_status ON verifications(status);

CREATE OR REPLACE FUNCTION complete_otc_cash_in(transaction_id_arg uuid)
RETURNS void AS $$
DECLARE
  trans RECORD;
BEGIN
  SELECT * INTO trans FROM public.transactions WHERE id = transaction_id_arg FOR UPDATE;

  IF NOT FOUND OR trans.status <> 'pending' OR trans.type <> 'cash_in' THEN
    RAISE EXCEPTION 'Transaction not found or not in a completable state.';
  END IF;

  UPDATE public.wallets
  SET balance = balance + trans.amount
  WHERE id = trans.wallet_id;

  UPDATE public.transactions
  SET 
    status = 'completed',
    processed_at = now()
  WHERE id = transaction_id_arg;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TYPE payment_method_type AS ENUM ('Over-the-Counter', 'E-Wallet', 'Online Banking');

CREATE TABLE payment_methods (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    type payment_method_type NOT NULL,
    is_active boolean DEFAULT true,
    description text,
    created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_payment_methods_type ON payment_methods(type);

ALTER TABLE public.transactions
  DROP COLUMN IF EXISTS payment_method_id,
  ADD COLUMN payment_method_id uuid REFERENCES payment_methods(id),
  ALTER COLUMN transaction_number DROP DEFAULT;

DROP FUNCTION IF EXISTS public.komyut_generate_transaction_number();

INSERT INTO public.payment_methods (name, type) VALUES
('Over-the-Counter', 'Over-the-Counter'),
('GCash', 'E-Wallet'),
('PayMaya', 'E-Wallet'),
('BPI', 'Online Banking'),
('BDO', 'Online Banking'),
('Metrobank', 'Online Banking'),
('Landbank', 'Online Banking');

CREATE OR REPLACE FUNCTION redeem_wheel_tokens(
    p_amount_to_redeem numeric,
    p_profile_id uuid,
    p_transaction_number text
)
RETURNS void AS $$
DECLARE
    v_commuter_id uuid;
    v_wallet_id uuid;
    v_current_tokens numeric;
    v_new_transaction_id uuid;
BEGIN
    SELECT c.id, w.id INTO v_commuter_id, v_wallet_id FROM profiles p JOIN commuters c ON p.id = c.profile_id JOIN wallets w ON p.id = w.owner_profile_id WHERE p.id = p_profile_id;
    IF v_commuter_id IS NULL OR v_wallet_id IS NULL THEN RAISE EXCEPTION 'Commuter or wallet not found'; END IF;
    SELECT wheel_tokens INTO v_current_tokens FROM commuters WHERE id = v_commuter_id FOR UPDATE;
    IF v_current_tokens < p_amount_to_redeem THEN RAISE EXCEPTION 'Insufficient wheel tokens'; END IF;
    
    UPDATE commuters SET wheel_tokens = wheel_tokens - p_amount_to_redeem WHERE id = v_commuter_id;
    UPDATE wallets SET balance = balance + p_amount_to_redeem WHERE id = v_wallet_id;
    
    INSERT INTO transactions (wallet_id, initiated_by_profile_id, type, amount, status, transaction_number, processed_at)
    VALUES (v_wallet_id, p_profile_id, 'token_redemption', p_amount_to_redeem, 'completed', p_transaction_number, now())
    RETURNING id INTO v_new_transaction_id;

    INSERT INTO points_transactions (commuter_id, change, reason, related_transaction_id, balance_after)
    VALUES (v_commuter_id, -p_amount_to_redeem, 'redemption', v_new_transaction_id, (v_current_tokens - p_amount_to_redeem));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP FUNCTION IF EXISTS public.get_weekly_fare_expenses();
DROP FUNCTION IF EXISTS public.get_weekly_fare_expenses(integer);

CREATE OR REPLACE FUNCTION public.get_weekly_fare_expenses(week_offset integer DEFAULT 0)
RETURNS TABLE(day_name text, total numeric) AS $$
DECLARE
    target_week_start date;
BEGIN
    target_week_start := date_trunc('week', now() + (week_offset * 7 || ' days')::interval)::date;

    RETURN QUERY
    WITH week_days AS (
        SELECT
            to_char(d, 'Dy') as day_name_short,
            d::date as full_date
        FROM generate_series(
            target_week_start,
            target_week_start + interval '6 days',
            '1 day'::interval
        ) as d
    )
    SELECT
        wd.day_name_short,
        COALESCE(SUM(t.amount), 0) AS total
    FROM week_days wd
    LEFT JOIN transactions t
        ON date_trunc('day', t.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Manila')::date = wd.full_date
        AND t.type = 'fare_payment'
        AND t.wallet_id = (
            SELECT w.id FROM wallets w
            JOIN profiles p ON w.owner_profile_id = p.id
            WHERE p.user_id = auth.uid()
            LIMIT 1
        )
    GROUP BY wd.day_name_short, wd.full_date
    ORDER BY wd.full_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_driver_weekly_earnings(week_offset integer DEFAULT 0)
RETURNS TABLE(day_name text, total numeric) AS $$
DECLARE
    v_driver_id uuid;
    target_week_start date;
BEGIN
    SELECT d.id INTO v_driver_id
    FROM public.profiles p
    JOIN public.drivers d ON p.id = d.profile_id
    WHERE p.user_id = auth.uid()
    LIMIT 1;

    IF v_driver_id IS NULL THEN
        RETURN;
    END IF;

    target_week_start := date_trunc('week', now() + (week_offset * 7 || ' days')::interval)::date;

    RETURN QUERY
    WITH week_days AS (
        SELECT generate_series(
            target_week_start,
            target_week_start + interval '6 days',
            '1 day'::interval
        )::date AS day
    )
    SELECT
        to_char(wd.day, 'Dy') AS day_name,
        COALESCE(SUM(t.fare_amount), 0) AS total
    FROM week_days wd
    LEFT JOIN trips t
        ON date_trunc('day', t.started_at AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Manila')::date = wd.day
        AND t.driver_id = v_driver_id
        AND t.status = 'completed'
    GROUP BY wd.day
    ORDER BY wd.day;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

ALTER TYPE transaction_type ADD VALUE IF NOT EXISTS 'remittance';

CREATE OR REPLACE FUNCTION process_driver_remittance(amount_to_remit numeric)
RETURNS void AS $$
DECLARE
  v_driver_user_id uuid;
  v_driver_profile_id uuid;
  v_driver_wallet_id uuid;
  v_operator_id uuid;
  v_operator_profile_id uuid;
  v_operator_wallet_id uuid;
  v_current_balance numeric;
  v_txn_number text;
BEGIN
  v_driver_user_id := auth.uid();

  SELECT p.id, w.id, d.operator_id
  INTO v_driver_profile_id, v_driver_wallet_id, v_operator_id
  FROM profiles p
  JOIN drivers d ON p.id = d.profile_id
  JOIN wallets w ON p.id = w.owner_profile_id
  WHERE p.user_id = v_driver_user_id;

  IF v_driver_wallet_id IS NULL THEN 
    RAISE EXCEPTION 'Driver wallet not found'; 
  END IF;
  
  IF v_operator_id IS NULL THEN 
    RAISE EXCEPTION 'You are not linked to an operator to remit to.'; 
  END IF;

  SELECT p.id, w.id
  INTO v_operator_profile_id, v_operator_wallet_id
  FROM operators o
  JOIN profiles p ON o.profile_id = p.id
  JOIN wallets w ON p.id = w.owner_profile_id
  WHERE o.id = v_operator_id;

  IF v_operator_wallet_id IS NULL THEN 
    RAISE EXCEPTION 'Operator wallet configuration error.'; 
  END IF;

  SELECT balance INTO v_current_balance FROM wallets WHERE id = v_driver_wallet_id FOR UPDATE;
  
  IF v_current_balance < amount_to_remit THEN 
    RAISE EXCEPTION 'Insufficient wallet balance.'; 
  END IF;

  v_txn_number := 'REM-' || floor(extract(epoch from now()));

  UPDATE wallets 
  SET balance = balance - amount_to_remit, updated_at = now()
  WHERE id = v_driver_wallet_id;

  UPDATE wallets 
  SET balance = balance + amount_to_remit, updated_at = now()
  WHERE id = v_operator_wallet_id;

  INSERT INTO transactions (
    wallet_id, initiated_by_profile_id, type, amount, status, transaction_number, metadata
  ) VALUES (
    v_driver_wallet_id, 
    v_driver_profile_id, 
    'remittance', 
    -amount_to_remit,
    'completed', 
    v_txn_number || '-DRV', 
    jsonb_build_object('recipient_operator_id', v_operator_id)
  );

  INSERT INTO transactions (
    wallet_id, initiated_by_profile_id, type, amount, status, transaction_number, metadata
  ) VALUES (
    v_operator_wallet_id, 
    v_driver_profile_id, 
    'remittance', 
    amount_to_remit, 
    'completed', 
    v_txn_number || '-OPR', 
    jsonb_build_object('sender_driver_id', v_driver_profile_id)
  );

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;