/// How [GlassSurface] renders.
enum GlassMode {
  /// Refractive Liquid Glass via `liquid_glass_renderer`. Without Impeller and
  /// Flutter GPU (e.g. Android today) the renderer falls back to its own
  /// frosted look automatically.
  liquid,

  /// Plain backdrop blur, independent of `liquid_glass_renderer`. The escape
  /// hatch if the renderer is ever dropped.
  frosted,

  /// No transparency. Backs the "reduce glass effect" setting.
  solid,
}
