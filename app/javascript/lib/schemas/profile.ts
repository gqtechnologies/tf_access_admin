import { z } from 'zod'
import { userValidationKeys, passwordSchema, passwordConfirmationSchema } from '@/lib/schemas/user'

const profileBaseSchema = z.object({
  name: z.string().min(1, userValidationKeys.name_required),
  dni: z.string().min(1, userValidationKeys.dni_required),
  email: z.string().email(userValidationKeys.email_invalid),
  password: passwordSchema,
  password_confirmation: passwordConfirmationSchema,
  language: z.string().min(1, userValidationKeys.language_required),
  avatar: z.instanceof(File).nullable(),
});

export const profileEditSchema = profileBaseSchema
  .omit({ password: true, password_confirmation: true })
  .extend({
    password: z.union([passwordSchema, z.literal('')]),
    password_confirmation: z.union([passwordConfirmationSchema, z.literal('')]),
  })
  .refine(
    (data) =>
      (!data.password && !data.password_confirmation) ||
      data.password === data.password_confirmation,
    { message: userValidationKeys.password_mismatch, path: ['password_confirmation'] }
  );


export type ProfileEditSchema = z.infer<typeof profileEditSchema>;