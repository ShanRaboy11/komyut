-- Trigger: create notifications automatically when transactions are inserted
-- This avoids requiring client INSERT permissions on notifications and ensures
-- a notification exists whenever wallet-related transactions are created.

CREATE OR REPLACE FUNCTION public.transactions_notify_trigger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  owner_profile uuid;
  driver_profile uuid;
  commuter_name text;
  title text;
  message text;
  payload jsonb;
BEGIN
  -- Resolve the wallet owner (the profile whose wallet was affected)
  IF NEW.wallet_id IS NOT NULL THEN
    SELECT owner_profile_id INTO owner_profile FROM public.wallets WHERE id = NEW.wallet_id;
  END IF;

  -- Build notification for wallet owner
  IF owner_profile IS NOT NULL THEN
    IF NEW.type = 'fare_payment' THEN
      title := 'Wallet debited';
      message := format('\u20B1%s was deducted from your wallet.', NEW.amount::text);
      payload := jsonb_build_object('transaction_id', NEW.id, 'amount', NEW.amount, 'action', 'debit', 'related_trip_id', NEW.related_trip_id);
    -- Do not create a generic "wallet credited" when the transaction is a driver_payout
    -- because a more specific "Payment received" notification is created for the driver below.
    ELSIF NEW.type IN ('operator_payout', 'cash_in') THEN
      title := 'Wallet credited';
      message := format('\u20B1%s was added to your wallet.', NEW.amount::text);
      payload := jsonb_build_object('transaction_id', NEW.id, 'amount', NEW.amount, 'action', 'credit', 'related_trip_id', NEW.related_trip_id);
    END IF;

    -- Only insert when we actually built a title/message/payload to avoid creating empty notifications
    IF title IS NOT NULL THEN
      INSERT INTO public.notifications (recipient_profile_id, type, title, message, payload, created_at)
      VALUES (owner_profile, 'wallet'::notification_type, title, message, payload, now());
    END IF;
  END IF;

  -- If this transaction relates to a trip, attempt to notify the trip's driver (credit events)
  IF NEW.related_trip_id IS NOT NULL THEN
    SELECT d.profile_id INTO driver_profile
    FROM public.drivers d
    JOIN public.trips t ON t.driver_id = d.id
    WHERE t.id = NEW.related_trip_id
    LIMIT 1;

    IF driver_profile IS NOT NULL THEN
      -- Notify driver when the inserted transaction represents a driver payout/credit
      IF NEW.type IN ('driver_payout', 'operator_payout') THEN
        -- Resolve commuter name (the trip owner) for a friendlier message
        SELECT p.first_name || ' ' || p.last_name
        INTO commuter_name
        FROM public.trips t
        JOIN public.profiles p ON p.id = t.created_by_profile_id
        WHERE t.id = NEW.related_trip_id
        LIMIT 1;

        INSERT INTO public.notifications (recipient_profile_id, type, title, message, payload, created_at)
        VALUES (
          driver_profile,
          'wallet'::notification_type,
          'Payment received',
          CASE WHEN commuter_name IS NOT NULL
            THEN format('\u20B1%s was received from %s.', NEW.amount::text, commuter_name)
            ELSE format('\u20B1%s was received for this trip.', NEW.amount::text)
          END,
          jsonb_build_object('transaction_id', NEW.id, 'amount', NEW.amount, 'action', 'credit', 'from_commuter_name', commuter_name, 'trip_id', NEW.related_trip_id),
          now()
        );
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- Trigger that runs after a transaction row is inserted
DROP TRIGGER IF EXISTS trg_transactions_notify ON public.transactions;
CREATE TRIGGER trg_transactions_notify
AFTER INSERT ON public.transactions
FOR EACH ROW
EXECUTE FUNCTION public.transactions_notify_trigger();
