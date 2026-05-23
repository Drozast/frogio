# PROMPT PARA CLAUDE.AI — PITCH DECK FROGIO

Copia y pega todo lo que está debajo de la línea en claude.ai (modelo Opus o Sonnet 4.x). Adjunta además el logo (`frogio-logo.png`) y los screenshots de la app si los quieres incluir.

---

## PROMPT

Actúa como un diseñador senior de pitch decks y estratega de ventas B2G (Business to Government). Tu tarea es crear una **presentación PDF profesional estilo pitch de 5 minutos** para presentar al **alcalde de una municipalidad chilena** y convencerlo de contratar el sistema **FROGIO**.

Debe ser **visualmente impactante**, con diseño moderno, jerarquía clara, íconos, tipografía grande tipo Keynote/Apple, uso de color y datos reales. Nada de slides con párrafos largos — es un pitch, no un informe.

### FORMATO DE ENTREGA
- PDF horizontal 16:9 (1920x1080)
- Genera el PDF completo usando código Python con **reportlab + matplotlib** (o la librería que prefieras que produzca un PDF descargable)
- Paleta de marca Frogio:
  - Verde esmeralda primario: `#1C8A52`
  - Verde esmeralda oscuro: `#1B6B40`
  - Verde claro: `#3BB774`
  - Azul marino: `#19334D`
  - Azul marino claro: `#2E4D6B`
  - Fondo claro: `#F5F7FA`
  - Texto: `#0F1C2E`
- Tipografía: sans-serif moderna (Helvetica/Inter equivalente)
- Cada slide debe ocupar toda la página, sin bordes blancos innecesarios
- Usa emojis/íconos unicode grandes como acentos visuales (🚨 🛡️ 📱 📊 🚛 🤖 ⚖️ 📍 🔔 ✅)

### ESTRUCTURA OBLIGATORIA (en este orden exacto)

**SLIDE 1 — PORTADA**
- Logo Frogio grande centrado (si no hay imagen, usa un placeholder tipográfico: "FROGIO" con un ícono de rana 🐸 o escudo 🛡️ en verde esmeralda)
- Tagline: "Seguridad Pública Municipal Inteligente"
- Subtítulo: "Presentación para la I. Municipalidad de [NOMBRE]"
- Fecha: Abril 2026
- Nombre del presentador: Damián Rozas — RD Digital SpA

**SLIDE 2 — EL PROBLEMA (parte 1)**
Título grande: "La seguridad municipal en Chile está en crisis"
Datos reales (ubícalos como cards con número gigante y descripción corta):
- 86,6% de los chilenos declara que la delincuencia aumentó en el último año (Paz Ciudadana 2024)
- Solo 1 de cada 5 chilenos confía en que su municipio responde rápido a emergencias (INE 2024)
- Las denuncias ciudadanas por WhatsApp, llamadas y papel se pierden: 40-60% queda sin trazabilidad
- Tiempo promedio de respuesta a una emergencia municipal: 22-45 minutos

**SLIDE 3 — EL PROBLEMA (parte 2)**
Título: "Lo que enfrenta hoy su municipalidad"
Lista visual con íconos:
- 📵 Comunicación fragmentada (WhatsApp, teléfono, papel, correo)
- 📝 Sin registro digital de infracciones ni citaciones → se pierden
- 🚨 No existe un canal directo de pánico ciudadano → minutos críticos perdidos
- 🚗 Sin bitácora digital de vehículos municipales → descontrol operativo
- 📊 Sin datos, sin reportes, sin inteligencia para tomar decisiones
- 👥 Ciudadanos frustrados, inspectores desconectados, jefaturas sin visibilidad

**SLIDE 4 — LA SOLUCIÓN: FROGIO**
Título gigante: "FROGIO" con tagline "Una sola plataforma. Tres perfiles. Cero caos."
Diagrama de 3 columnas:
1. 📱 **App Ciudadana** — denuncias, pánico, información médica
2. 📱 **App Inspector** — terreno, infracciones, bitácora, emergencias
3. 💻 **Panel Administrador** — control total, reportes, estadísticas

Frase de cierre: "Todo en tiempo real. Todo trazable. Todo auditable."

**SLIDE 5 — QUIÉN ESTÁ DETRÁS**
Título: "Sobre el desarrollador"
- **Damián Rozas** — Fundador de RD Digital SpA
- Full-stack developer con experiencia en SaaS y soluciones cloud
- Operador de infraestructura propia self-hosted (soberanía de datos 100% chilena)
- Portfolio: Frogio, RHOM, Casa Infante, BarberBook, Reclamaya, AgendAuto
- Contacto: rddigitalspa@gmail.com
- Stack moderno: Flutter, Node.js, PostgreSQL, Docker, Cloudflare

**SLIDE 6 — CARACTERÍSTICAS CORE (vista general)**
Grid de 6 tarjetas con ícono y título corto:
- 🚨 Botón de Pánico con GPS y ficha médica
- 📝 Denuncias ciudadanas georreferenciadas con fotos
- ⚖️ Infracciones y citaciones digitales con firma
- 🚗 Bitácora de vehículos municipales
- 📊 Reportes PDF/Excel automáticos
- 🔔 Alertas y notificaciones push en tiempo real

**SLIDE 7 — PERFIL CIUDADANO**
Título: "Para el vecino de la comuna"
Columna izquierda (texto con íconos):
- Crear cuenta con RUT y perfil médico
- Reportar problemas con foto + GPS en 30 segundos
- **Botón de pánico de emergencia** — alerta automática a inspectores con ubicación, foto, grupo sanguíneo, alergias y contactos
- Ver estado de sus denuncias en tiempo real
- Recibir notificaciones cuando el municipio actúa

Columna derecha: mockup de la app (placeholder de teléfono con pantallas verdes)

**SLIDE 8 — PERFIL INSPECTOR**
Título: "Para el inspector en terreno"
- Ver denuncias asignadas con mapa y fotos
- Crear infracciones con fotos, firma digital y GPS
- Emitir citaciones con patente → muestra historial del vehículo
- **Bitácora de viaje**: vehículo, kilometraje, personal, ruta, resumen
- **Recibir alertas de pánico** con sonido insistente y acceso inmediato a ficha médica
- Buscar por RUT / patente / dirección todo el historial

**SLIDE 9 — PERFIL ADMINISTRADOR (WEB)**
Título: "Para la jefatura municipal"
- Dashboard en tiempo real: denuncias, infracciones, emergencias, recaudación
- Asignar denuncias a inspectores con un clic
- Gestionar usuarios, vehículos y permisos
- **Reportes automáticos** PDF/Excel (diarios, semanales, mensuales)
- **Alertas automáticas**: denuncias sin atender 24h, pánicos sin respuesta 5 min, bitácoras incompletas
- Data Explorer con búsqueda unificada

**SLIDE 10 — TECNOLOGÍA Y SEGURIDAD**
Título: "Construido con estándares modernos"
- 🔒 Self-hosted 100% en Chile (soberanía de datos)
- 🔐 Encriptación, JWT, bcrypt, HTTPS obligatorio
- 📱 Flutter (iOS + Android nativo)
- ⚙️ Node.js + PostgreSQL + Docker
- ☁️ Cloudflare Tunnel (sin puertos abiertos, sin riesgos)
- 🧩 Multi-tenant: aislación total entre municipalidades

**SLIDE 11 — PLANES Y PRECIOS**
Título: "Dos formas de contratar Frogio"
Dos cards grandes lado a lado:

**CARD 1 — PLAN ANUAL** (con badge "5% DESCUENTO" en verde)
- **$2.000.000 + IVA / año**
- Descuento 5% aplicado
- Contratos 1, 2 o más años (descuento adicional por volumen negociable)
- Instalación + despliegue + mantenimiento incluidos
- Implementación: **3 meses**
- Soporte técnico continuo
- Actualizaciones de seguridad

**CARD 2 — PLAN MENSUAL** (con badge "MÁS FLEXIBLE" en azul)
- **$2.000.000 + IVA / mes**
- Todo lo del plan anual +
- **Adaptaciones y cambios mensuales ilimitados** (colores, logos, flujos, nuevas funciones menores)
- App 100% personalizada a la identidad visual del municipio
- Roadmap mensual conjunto con la alcaldía
- Ideal para municipalidades que requieren evolución continua

Al pie: "Todos los valores son netos, no incluyen IVA. Instalación, despliegue y mantenimiento incluidos en ambos planes."

**SLIDE 12 — ¿POR QUÉ FROGIO? (JUSTIFICACIÓN)**
Título: "Lo que logra su municipalidad"
Cards con impacto tangible:
- ⏱️ **-70% tiempo de respuesta** en emergencias (pánico con GPS vs. llamada telefónica)
- 📈 **+300% trazabilidad** de denuncias (cero pérdida de papel/WhatsApp)
- 💰 **+40% recaudación** de multas (infracciones digitales no se extravían)
- 👁️ **100% visibilidad** operativa para jefaturas
- 🤝 **Percepción ciudadana** — transparencia y respuesta rápida = reelección
- 📉 Reducción de costos administrativos por digitalización

Ata cada punto al dato del slide 2-3 como "antes vs. con Frogio"

**SLIDE 13 — ROADMAP: LO QUE VIENE**
Título: "Frogio evoluciona con su municipio"
Timeline horizontal con 2 hitos principales:

1. 🚛 **Seguimiento de Camiones de Basura** (en desarrollo)
   - GPS en tiempo real de la flota
   - Rutas optimizadas y cumplimiento
   - Ciudadanos pueden ver "¿cuándo pasa el camión por mi casa?"
   - Reportes de eficiencia

2. 🤖 **Consulta Inteligente con IA de Documentos Municipales**
   - Digitalización masiva de resoluciones, memos, oficios, ordenanzas
   - Chat con IA que responde consultas internas (funcionarios)
   - Portal público para ciudadanos: "Pregúntale a tu municipio"
   - Trazabilidad y citas textuales a los documentos originales

Mensaje de cierre: "Contratando Frogio, accede al ecosistema completo sin costo adicional de integración."

**SLIDE 14 — LLAMADO A LA ACCIÓN**
Título gigante: "Hagamos de [NOMBRE MUNICIPIO] una comuna más segura"
- Próximo paso: demo en vivo y propuesta formal
- Implementación en **90 días**
- Contacto: **Damián Rozas** — rddigitalspa@gmail.com
- Web: **frogio.cl**
- "Juntos transformamos la seguridad pública municipal"

**SLIDE 15 — GRACIAS**
Logo Frogio grande, verde esmeralda, fondo oscuro navy. Texto: "GRACIAS" + "¿Preguntas?"

---

### INSTRUCCIONES TÉCNICAS PARA GENERAR EL PDF

1. Usa Python con **reportlab** (o `pypdf`, `fpdf2`, `weasyprint` si prefieres HTML→PDF)
2. Tamaño: landscape, 16:9, 1920x1080 pt (o A4 landscape si es más simple)
3. Genera gráficos simples con matplotlib cuando haya datos (slide 2, 12)
4. Cada slide en su propia página
5. Márgenes generosos: 60-80 pt
6. Tipografía grande: títulos 48-72pt, subtítulos 28-36pt, cuerpo 18-22pt
7. Al final, guarda como `Frogio_Pitch_Alcalde.pdf` y déjalo disponible para descarga
8. **Devuélveme el archivo PDF final**, no solo el código

### TONO
- Directo, profesional, confiado, sin tecnicismos innecesarios
- El alcalde NO es técnico → habla de impacto, no de stack
- Énfasis en: seguridad del vecino, control operativo, imagen política, datos reales
- Cada slide debe poder leerse en 20 segundos

Empieza generando el PDF ahora. Muéstrame cada slide visualmente mientras lo construyes para validar el diseño antes de compilar el PDF final.
