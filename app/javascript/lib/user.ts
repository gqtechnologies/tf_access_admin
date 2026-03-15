import { User } from "@/types/user"

export const getUserFallback = (user: User) => {
    return user.name.charAt(0) + user.name.split(' ').pop()?.charAt(0)
}