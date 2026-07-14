# Design language

Ayame Shell combines three influences without copying an existing shell:

- Material You: adaptive color, expressive shape, and clear state changes
- Fluent design: layered desktop surfaces, restraint, and practical density
- anime-inspired identity: wallpaper artwork and optional accent details

## Principles

1. The interface should look like one system rather than unrelated widgets.
2. Color names describe purpose (`primary`, `surface`, `foregroundSurface`) so a
   wallpaper-generated palette can replace the default palette safely.
3. Spacing and corner radii come from shared scales.
4. Motion communicates state. Hover, press, selection, opening, and closing
   should feel related rather than using random effects.
5. Most animation uses opacity, color, scale, or position. Blur and shaders are
   reserved for places where they materially improve the design.
6. Wallpaper colors may change personality, but readable contrast is never
   optional.

## Initial motion scale

- Fast, 120 ms: hover and press feedback
- Normal, 220 ms: selection and small shape changes
- Slow, 360 ms: future panels entering or changing layout

The fallback palette is a hand-authored dark violet theme. Optional wallpaper
colors use Matugen to replace the same semantic values with a dark tonal,
vibrant, or expressive scheme. Surfaces remain restrained while active states,
controls, highlights, and readable foregrounds follow the wallpaper palette.
Returning to Ayame Violet never requires regenerating or deleting the cache.
Follow Wallpaper is the primary experience: a wallpaper change keeps the old
palette visible until the replacement is ready, then every semantic surface and
accent updates together. Manual mode exists for users whose wallpaper service
does not expose its current image or who intentionally want a different palette.

Both dark and light appearances are full semantic palettes rather than inverted
surface colors. Optional wallpaper tint gives large shell surfaces more of the
source hue, while optional blur lowers their opacity and lets Hyprland soften
the wallpaper beneath them. Each effect is independently reversible.

Quick Settings answers “what changes this session?”; Ayame Settings answers
“how should my shell look and behave?”. Keeping those purposes separate prevents
device controls from being buried among long-lived personalization choices.

The dock launcher uses a neutral nine-dot application grid rather than a letter
or brand mark. It remains recognizable across languages and lets wallpaper-driven
color communicate its active state without tying the shell to a wordmark.

## Typography

Ayame uses Adwaita Sans for interface text, with Medium body copy, bold labels,
Bold titles, and ExtraBold reserved for rare display emphasis. JetBrains Mono is
limited to compact numeric readouts such as time, percentages, workspace numbers,
calendar dates, and playback position. This keeps the interface warm and readable
without making every surface visually loud.

## Panel motion

Clock-owned panels use the clock's bottom center as their visual origin. They
enter by unfolding downward, fading in, and settling a short distance below the
bar. Closing reverses the same path so the panel appears to return into its
trigger rather than simply disappearing.

Reduced motion is a first-class preference. Disabling animations sets the shared
fast, normal, and slow durations to zero, preserving every state change and
interaction while removing transitional movement across the shell.

Layout density is also expressed through shared theme tokens. Comfortable mode
keeps the default breathing room, while compact mode tightens shell margins,
major gaps, bar and dock height, and wide bar regions without changing content
or interaction targets unexpectedly.

The bar reserves equal left and right regions to keep the clock geometrically
centered. Those regions grow responsively on wide displays so workspace paging
and active-window context receive useful space, then shrink together on compact
screens. Window titles remain still rather than adding perpetual marquee motion.

Calendar month changes preserve spatial direction: later months travel left and
enter from the right, while earlier months do the reverse. Clock text uses two
layers so compact time and expanded date crossfade and settle instead of swapping
in a single frame.
