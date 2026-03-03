import { z } from "zod"

export const loginSchema = z.object({
    user: z.object({
      email: z.string().min(1, "El email es requerido").email("Email no válido"),
      password: z.string().min(1, "La contraseña es requerida")
    }),
  });
  
export type LoginInput = z.infer<typeof loginSchema>;