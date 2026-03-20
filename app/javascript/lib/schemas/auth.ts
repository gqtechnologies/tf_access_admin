import { z } from "zod"
import { passwordSchema, passwordConfirmationSchema, userValidationKeys } from "./user";

export const loginSchema = z.object({
    user: z.object({
      email: z.string().min(1, userValidationKeys.email_required).email(userValidationKeys.email_invalid),
      password: z.string().min(1, userValidationKeys.password_required)
    }),
  });
  

export const newPasswordSchema = z.object({
  user: z.object({
    email: z.string().min(1, userValidationKeys.email_required).email(userValidationKeys.email_invalid),
  }),
});

export const editPasswordSchema = z.object({
  user: z.object({
    reset_password_token: z.string().min(1, userValidationKeys.reset_password_token_required),
    password: passwordSchema,
    password_confirmation: passwordConfirmationSchema,
  }),
}).refine((data) => data.user.password === data.user.password_confirmation, {
  message: userValidationKeys.password_mismatch,
  path: ['user.password_confirmation'],
});

export type LoginInput = z.infer<typeof loginSchema>;
export type EditPasswordInput = z.infer<typeof editPasswordSchema>;
export type NewPasswordInput = z.infer<typeof newPasswordSchema>;