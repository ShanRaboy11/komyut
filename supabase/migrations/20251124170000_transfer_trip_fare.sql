-- Migration: create transfer_trip_fare function (recreated)
-- Performs an authorized transfer of trip fare to the driver wallet.
-- SECURITY DEFINER function that verifies the trip belongs to the calling commuter
-- and then credits the driver's wallet and finalizes pending transactions.

CREATE OR REPLACE FUNCTION public.transfer_trip_fare(
  p_trip_id uuid,
  p_driver_profile_id uuid,
  p_amount numeric,
  p_commuter_profile_id uuid
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_wallet_id uuid;
  v_exists int;
BEGIN
  -- Verify caller is the commuter who created the trip
  SELECT 1 INTO v_exists FROM trips t
    WHERE t.id = p_trip_id AND t.created_by_profile_id = p_commuter_profile_id;

  IF v_exists IS NULL THEN
    RAISE EXCEPTION 'Trip does not belong to the caller (commuter)';
  END IF;

  -- Ensure driver wallet exists; create if missing
  SELECT id INTO v_wallet_id FROM wallets WHERE owner_profile_id = p_driver_profile_id LIMIT 1;

  IF v_wallet_id IS NULL THEN
    INSERT INTO wallets (owner_profile_id, balance, created_at, updated_at)
    VALUES (p_driver_profile_id, 0, now(), now())
    RETURNING id INTO v_wallet_id;
  END IF;

  -- Credit driver wallet
  UPDATE wallets
  SET balance = balance + p_amount,
      updated_at = now()
  WHERE id = v_wallet_id;

  -- Insert driver payout transaction for auditing
  INSERT INTO transactions (
    transaction_number,
    wallet_id,
    initiated_by_profile_id,
    type,
    amount,
    status,
    related_trip_id,
    processed_at,
    metadata
  ) VALUES (
    'KOMYUT-PAYOUT-' || (extract(epoch from now())::bigint) || '-' || floor(random()*10000)::int,
    v_wallet_id,
    p_driver_profile_id,
    'driver_payout',
    p_amount,
    'completed',
    p_trip_id,
    now(),
    jsonb_build_object('reason','trip_fare','trip_id', p_trip_id)
  );

  -- Mark any pending transactions for this trip as completed
  UPDATE transactions
  SET status = 'completed', processed_at = now()
  WHERE related_trip_id = p_trip_id AND status = 'pending';

END;
$function$;

-- Allow authenticated users to call this RPC (it performs its own authorization check)
GRANT EXECUTE ON FUNCTION public.transfer_trip_fare(uuid, uuid, numeric, uuid) TO authenticated;
