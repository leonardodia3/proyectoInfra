# Frontend design system

## Direction

Panel operativo para demo local y despliegue estatico. La direccion visual es clara, densa y utilitaria, con fondo claro, tarjetas blancas, bordes visibles y contraste alto para que los formularios y tablas se lean sin esfuerzo.

## Tokens

- Background: `--bg`
- Panel: `--panel`
- Border: `--border`
- Text: `--text`
- Muted text: `--muted`
- Accent: `--accent`
- Accent dim: `--accent-dim`
- Success: `--success`
- Success soft: `--success-soft`
- Error: `--error`
- Field: `--field`
- Soft surface: `--surface-soft`

## Typography

- Family: `"Segoe UI", system-ui, -apple-system, sans-serif`
- Page title: 18px, weight 600
- Panel title: 15px, uppercase, muted
- Labels/table text: 13px
- Inputs/buttons: 14px

## Spacing

- Page max width: 1100px
- Grid gap: 20px
- Panel padding: 22px
- Form gap: 12px
- Input/button radius: 6px

## Primitives

- `topbar`: status header for the local environment.
- `panel`: bordered white surface for one workflow.
- `panel-header`: compact header with title and status.
- `status-pill`: small environment/authentication state label.
- `feedback`: inline success/error message.
- `students-table`: dense table for repeated student records.
- Mobile student records: table rows become stacked labeled records below 720px.
- Table message rows: empty/loading/error rows do not use mobile field labels.
- `button-row`: horizontal command group, wrapping on narrow screens.
- `api.js`, `auth.js`, `app.js`: separate API/session, auth helpers and screen workflows.
- `style.css`, `responsive.css`: base/component styles are separated from responsive rules.

## Accessibility

- Inputs keep visible labels.
- Focus state uses accent border.
- Feedback text is inline and does not rely on alerts.
- Tables remain horizontally scrollable on mobile.
- Deployed Cognito controls appear only when `window.APP_CONFIG.mode` is `aws`.
