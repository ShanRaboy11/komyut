-- Allow users to SELECT attachments that are associated with reports they can view
-- This is a scoped policy that keeps attachments protected while permitting
-- access when the attachment is attached to a report visible to the user.

CREATE POLICY "attachments_select_for_reports"
ON public.attachments
FOR SELECT
TO authenticated
USING (
  is_admin()
  OR (
    EXISTS (
      SELECT 1 FROM public.reports r
      WHERE r.attachment_id = attachments.id
        AND (
          -- reporter can view their own reports
          r.reporter_profile_id IN (
            SELECT id FROM public.profiles WHERE user_id = auth.uid()
          )
          -- OR assigned profile (driver) can view
          OR r.assigned_to_profile_id IN (
            SELECT id FROM public.profiles WHERE user_id = auth.uid()
          )
          -- OR operator can view reports for drivers they manage
          OR (
            r.reported_entity_type = 'driver'::text
            AND r.reported_entity_id IN (
              SELECT d.id FROM public.drivers d
              WHERE d.operator_id IN (
                SELECT o.id FROM public.operators o
                WHERE o.profile_id IN (
                  SELECT id FROM public.profiles WHERE user_id = auth.uid() AND role = 'operator'
                )
              )
            )
          )
        )
    )
  )
);
