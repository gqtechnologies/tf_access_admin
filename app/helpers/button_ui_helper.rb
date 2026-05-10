module ButtonUiHelper
  SHADCN_BUTTON_BASE_CLASSES = "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-all disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg:not([class*='size-'])]:size-4 shrink-0 [&_svg]:shrink-0 outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px] aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive cursor-pointer".freeze

  SHADCN_BUTTON_VARIANTS = {
    default: "bg-primary text-primary-foreground hover:bg-primary/90",
    destructive: "bg-destructive text-white hover:bg-destructive/90 focus-visible:ring-destructive/20 dark:focus-visible:ring-destructive/40 dark:bg-destructive/60",
    outline: "border bg-background shadow-xs hover:bg-accent hover:text-accent-foreground dark:bg-input/30 dark:border-input dark:hover:bg-input/50",
    secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/80",
    ghost: "hover:bg-accent hover:text-accent-foreground dark:hover:bg-accent/50",
    link: "text-primary underline-offset-4 hover:underline"
  }.freeze

  SHADCN_BUTTON_SIZES = {
    default: "h-9 px-4 py-2 has-[>svg]:px-3",
    sm: "h-8 rounded-md gap-1.5 px-3 has-[>svg]:px-2.5",
    lg: "h-10 rounded-md px-6 has-[>svg]:px-4",
    icon: "size-9",
    "icon-sm": "size-8",
    "icon-lg": "size-10"
  }.freeze

  def shadcn_button_classes(variant: :default, size: :default, class_name: nil)
    variant_classes = SHADCN_BUTTON_VARIANTS.fetch(variant.to_sym, SHADCN_BUTTON_VARIANTS[:default])
    size_key = size.to_s.tr("_", "-").to_sym
    size_classes = SHADCN_BUTTON_SIZES.fetch(size_key, SHADCN_BUTTON_SIZES[:default])

    [ SHADCN_BUTTON_BASE_CLASSES, variant_classes, size_classes, class_name ].compact.join(" ")
  end
end
