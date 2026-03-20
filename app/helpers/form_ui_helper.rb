module FormUiHelper
  def shadcn_field_label_classes
    "group/field-label peer/field-label flex w-fit gap-2 leading-snug " \
      "group-data-[disabled=true]/field:opacity-50"
  end

  def shadcn_input_group_classes
    "group/input-group border-input dark:bg-input/30 relative flex w-full items-center " \
      "rounded-md border shadow-xs transition-[color,box-shadow] outline-none h-9 min-w-0 " \
      "has-[[data-slot=input-group-control]:focus-visible]:border-ring " \
      "has-[[data-slot=input-group-control]:focus-visible]:ring-ring/50 " \
      "has-[[data-slot=input-group-control]:focus-visible]:ring-[3px] " \
      "has-[[data-slot][aria-invalid=true]]:ring-destructive/20 " \
      "has-[[data-slot][aria-invalid=true]]:border-destructive " \
      "dark:has-[[data-slot][aria-invalid=true]]:ring-destructive/40 overflow-hidden"
  end

  def shadcn_input_group_addon_classes(align: "inline-start")
    base = "text-muted-foreground flex h-auto cursor-text items-center justify-center gap-2 " \
      "py-1.5 pr-3 text-sm font-medium select-none [&>svg:not([class*='size-'])]:size-4 " \
      "group-data-[disabled=true]/input-group:opacity-50"

    variants = {
      "inline-start" => "order-first pl-3",
      "inline-end" => "order-last pr-3",
      "block-start" => "order-first w-full justify-start px-3 pt-3",
      "block-end" => "order-last w-full justify-start px-3 pb-3"
    }

    "#{base} #{variants.fetch(align.to_s, variants['inline-start'])}"
  end

  def shadcn_input_group_input_classes
    "flex-1 rounded-none border-0 bg-transparent shadow-none focus-visible:ring-0 dark:bg-transparent"
  end
end
