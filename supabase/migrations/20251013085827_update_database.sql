ALTER TABLE profiles 
DROP COLUMN IF EXISTS dob;

ALTER TABLE profiles 
DROP COLUMN IF EXISTS phone;

ALTER TABLE operators 
DROP COLUMN IF EXISTS contact_phone;

SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'profiles' 
ORDER BY ordinal_position;

DO $$
BEGIN
    RAISE NOTICE 'Successfully removed dob and phone columns from profiles table';
END $$;