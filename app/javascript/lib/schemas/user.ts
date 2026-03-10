import { z } from 'zod'

export const userValidationKeys = {
  name_required: 'users.validations.name_required',
  dni_required: 'users.validations.dni_required',
  email_invalid: 'users.validations.email_invalid',
  password_min: 'users.validations.password_min',
  password_confirmation_min: 'users.validations.password_confirmation_min',
  password_mismatch: 'users.validations.password_mismatch',
  role_required: 'users.validations.role_required',
  language_required: 'users.validations.language_required',
  password_lowercase: 'users.validations.password_lowercase',
  password_uppercase: 'users.validations.password_uppercase',
  password_symbol: 'users.validations.password_symbol',
} as const

export const userSchema = z
  .object({
    name: z.string().min(1, userValidationKeys.name_required),
    dni: z.string().min(1, userValidationKeys.dni_required),
    email: z.string().email(userValidationKeys.email_invalid),
    password: z.string().min(8, userValidationKeys.password_min)
    .regex(/[a-z]/, { message: userValidationKeys.password_lowercase })
    .regex(/[A-Z]/, { message: userValidationKeys.password_uppercase })
    .regex(/[$%@.\-_]/, { message: userValidationKeys.password_symbol }),
    password_confirmation: z.string().min(8, userValidationKeys.password_confirmation_min),
    role: z.string().min(1, userValidationKeys.role_required),
    language: z.string().min(1, userValidationKeys.language_required),
  })
  .refine((data) => data.password === data.password_confirmation, {
    message: userValidationKeys.password_mismatch,
    path: ['password_confirmation'],
  })

export type UserSchema = z.infer<typeof userSchema>;