/// How [GlassSurface] renders.
enum GlassMode {
  /// Refractive Liquid Glass via `liquid_glass_renderer`. Without Impeller and
  /// Flutter GPU (e.g. Android today) the renderer falls back to its own
  /// frosted look automatically.
  liquid,

  /// Backdrop blur with a top sheen, independent of `liquid_glass_renderer`.
  /// The default: it looks the same on every platform and never refracts
  /// the text behind it.
  frosted,

  /// No transparency. Backs the "reduce glass effect" setting.
  solid,
}
