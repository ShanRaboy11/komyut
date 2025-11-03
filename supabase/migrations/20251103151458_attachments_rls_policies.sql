-- Allow authenticated users to upload to attachments bucket
CREATE POLICY "Authenticated users can upload attachments"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'attachments');

-- Allow public read access to attachments
CREATE POLICY "Public can view attachments"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'attachments');

-- Allow authenticated users to update their own attachments
CREATE POLICY "Users can update own attachments"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'attachments');

-- Allow authenticated users to delete their own attachments
CREATE POLICY "Users can delete own attachments"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'attachments');