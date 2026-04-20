import { ArrowLeft } from "lucide-react";
import { Link } from "react-router-dom";

const PrivacyPolicy = () => {
  const lastUpdated = "19 de abril de 2026";
  const developerEmail = "privacidad@frogio.cl";

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="border-b border-border bg-background/95 backdrop-blur sticky top-0 z-50">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center gap-4">
          <Link
            to="/"
            className="flex items-center gap-2 text-muted-foreground hover:text-primary transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
            <span className="text-sm font-medium">Volver al inicio</span>
          </Link>
        </div>
      </header>

      {/* Content */}
      <main className="max-w-4xl mx-auto px-4 py-12">
        <article className="prose prose-neutral dark:prose-invert max-w-none">
          <h1 className="text-3xl md:text-4xl font-bold text-foreground mb-2">
            Política de Privacidad
          </h1>
          <p className="text-muted-foreground text-lg mb-8">
            Frogio: Seguridad Municipal
          </p>
          <p className="text-sm text-muted-foreground mb-8">
            Última actualización: {lastUpdated}
          </p>

          <div className="space-y-8 text-foreground/90">
            {/* Introducción */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                1. Introducción
              </h2>
              <p className="leading-relaxed mb-4">
                Bienvenido a <strong>Frogio: Seguridad Municipal</strong> (en adelante, "la Aplicación"),
                desarrollada por <strong>drozast</strong> (en adelante, "el Desarrollador"). Esta Política
                de Privacidad describe cómo recopilamos, utilizamos, almacenamos y protegemos la información
                personal de los usuarios de nuestra aplicación móvil.
              </p>
              <p className="leading-relaxed mb-4">
                Al utilizar la Aplicación, usted acepta las prácticas descritas en esta Política de Privacidad.
                Si no está de acuerdo con estas prácticas, le recomendamos no utilizar la Aplicación.
              </p>
              <p className="leading-relaxed">
                <strong>Identificador de la aplicación:</strong> com.frogio.santa_juana<br />
                <strong>País de operación:</strong> Chile
              </p>
            </section>

            {/* Datos recopilados */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                2. Información que Recopilamos
              </h2>

              <h3 className="text-lg font-medium text-foreground mb-3">
                2.1 Información Personal
              </h3>
              <p className="leading-relaxed mb-4">
                Recopilamos la siguiente información personal que usted nos proporciona voluntariamente:
              </p>
              <ul className="list-disc pl-6 space-y-2 mb-6">
                <li><strong>Nombre completo:</strong> Para identificar al usuario en el sistema.</li>
                <li><strong>Correo electrónico:</strong> Para comunicaciones y notificaciones.</li>
                <li><strong>RUT (Rol Único Tributario):</strong> Para verificación de identidad ante la municipalidad.</li>
                <li><strong>Número de teléfono:</strong> Para contacto en caso de emergencias y notificaciones SMS.</li>
              </ul>

              <h3 className="text-lg font-medium text-foreground mb-3">
                2.2 Datos de Ubicación
              </h3>
              <p className="leading-relaxed mb-4">
                La Aplicación recopila datos de ubicación GPS para las siguientes funcionalidades:
              </p>
              <ul className="list-disc pl-6 space-y-2 mb-6">
                <li>Geolocalización de denuncias ciudadanas.</li>
                <li>Activación y transmisión de alertas de emergencia (botón SOS).</li>
                <li>Seguimiento de vehículos e inspectores municipales (solo para personal autorizado).</li>
              </ul>
              <p className="leading-relaxed mb-4 p-4 bg-primary/5 border border-primary/20 rounded-lg">
                <strong>Nota importante:</strong> La ubicación se recopila únicamente cuando usted utiliza
                activamente estas funcionalidades o cuando ha otorgado permiso expreso para el seguimiento
                en segundo plano (aplicable solo a inspectores municipales).
              </p>

              <h3 className="text-lg font-medium text-foreground mb-3">
                2.3 Archivos Multimedia
              </h3>
              <p className="leading-relaxed mb-4">
                Cuando usted adjunta fotografías, videos o documentos a sus denuncias, estos archivos
                son almacenados en nuestros servidores seguros para ser procesados por la municipalidad correspondiente.
              </p>

              <h3 className="text-lg font-medium text-foreground mb-3">
                2.4 Datos del Dispositivo y Diagnóstico
              </h3>
              <p className="leading-relaxed mb-4">
                Recopilamos información técnica del dispositivo para el funcionamiento de las notificaciones
                push y para detectar fallas de la Aplicación:
              </p>
              <ul className="list-disc pl-6 space-y-2">
                <li>Token de notificaciones push (Firebase Cloud Messaging y APNs de Apple).</li>
                <li>Sistema operativo y versión.</li>
                <li>Modelo del dispositivo.</li>
                <li>
                  <strong>Reportes de fallas (Firebase Crashlytics):</strong> stack traces y contexto técnico
                  cuando la Aplicación presenta errores, sin información personal identificable.
                </li>
              </ul>
            </section>

            {/* SOS disclaimer */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                2 bis. Aviso importante sobre el botón SOS
              </h2>
              <p className="leading-relaxed mb-4 p-4 bg-red-500/5 border border-red-500/30 rounded-lg">
                <strong>El botón SOS de la Aplicación NO reemplaza a los servicios de emergencia oficiales.</strong>
                {" "}Es un canal complementario que notifica a inspectores municipales de la Municipalidad de
                Santa Juana. Para emergencias que requieran intervención inmediata de Carabineros, Bomberos
                o Ambulancia, llame siempre a <strong>133 (Carabineros)</strong>, <strong>132 (Bomberos)</strong>
                {" "}o <strong>131 (SAMU)</strong>. La Aplicación puede no estar disponible por fallas de red,
                cobertura o batería del dispositivo.
              </p>
            </section>

            {/* Uso de datos */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                3. Cómo Utilizamos su Información
              </h2>
              <p className="leading-relaxed mb-4">
                Utilizamos la información recopilada para los siguientes propósitos:
              </p>
              <ul className="list-disc pl-6 space-y-2">
                <li><strong>Gestión de denuncias ciudadanas:</strong> Procesar, categorizar y dar seguimiento a los reportes realizados.</li>
                <li><strong>Alertas de emergencia SOS:</strong> Transmitir su ubicación y datos de contacto a la Central de Seguridad Ciudadana en situaciones de emergencia.</li>
                <li><strong>Seguimiento de vehículos municipales:</strong> Optimizar las rutas y tiempos de respuesta del personal municipal.</li>
                <li><strong>Notificaciones:</strong> Informarle sobre el estado de sus denuncias, alertas de seguridad y comunicaciones municipales relevantes.</li>
                <li><strong>Mejora del servicio:</strong> Analizar patrones de uso para mejorar la funcionalidad de la Aplicación.</li>
                <li><strong>Cumplimiento legal:</strong> Cumplir con requerimientos legales y solicitudes de autoridades competentes.</li>
              </ul>
            </section>

            {/* Compartir datos */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                4. Con Quién Compartimos su Información
              </h2>
              <p className="leading-relaxed mb-4">
                Su información personal puede ser compartida con:
              </p>
              <ul className="list-disc pl-6 space-y-2 mb-6">
                <li><strong>Municipalidad correspondiente:</strong> Para la gestión y resolución de denuncias ciudadanas.</li>
                <li><strong>Central de Seguridad Ciudadana:</strong> En caso de activación de alertas de emergencia.</li>
                <li><strong>Carabineros de Chile:</strong> Cuando las denuncias o emergencias requieran intervención policial.</li>
                <li><strong>Proveedores de servicios tecnológicos:</strong> Empresas que nos ayudan a operar la Aplicación (hosting, notificaciones), bajo estrictos acuerdos de confidencialidad.</li>
              </ul>
              <p className="leading-relaxed p-4 bg-primary/5 border border-primary/20 rounded-lg">
                <strong>No vendemos ni alquilamos</strong> su información personal a terceros con fines comerciales o de marketing.
              </p>
            </section>

            {/* Almacenamiento y seguridad */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                5. Almacenamiento y Seguridad de Datos
              </h2>
              <p className="leading-relaxed mb-4">
                Implementamos medidas de seguridad técnicas y organizativas para proteger su información personal:
              </p>
              <ul className="list-disc pl-6 space-y-2 mb-6">
                <li>Cifrado de datos en tránsito (TLS/SSL) y en reposo.</li>
                <li>Acceso restringido a la información personal solo a personal autorizado.</li>
                <li>Servidores seguros con monitoreo continuo.</li>
                <li>Copias de seguridad regulares.</li>
              </ul>
              <p className="leading-relaxed">
                Los datos se almacenan en servidores ubicados en Chile y/o proveedores de nube con
                certificaciones de seguridad internacionales. Conservamos su información mientras
                mantenga una cuenta activa y por el período adicional requerido por la legislación chilena.
              </p>
            </section>

            {/* Derechos del usuario */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                6. Sus Derechos
              </h2>
              <p className="leading-relaxed mb-4">
                De acuerdo con la Ley N° 19.628 sobre Protección de la Vida Privada de Chile y el
                Reglamento General de Protección de Datos (GDPR) de la Unión Europea, usted tiene los siguientes derechos:
              </p>
              <ul className="list-disc pl-6 space-y-2 mb-6">
                <li><strong>Derecho de acceso:</strong> Solicitar información sobre los datos personales que tenemos sobre usted.</li>
                <li><strong>Derecho de rectificación:</strong> Corregir datos inexactos o incompletos.</li>
                <li><strong>Derecho de cancelación/supresión:</strong> Solicitar la eliminación de sus datos personales.</li>
                <li><strong>Derecho de oposición:</strong> Oponerse al tratamiento de sus datos para fines específicos.</li>
                <li><strong>Derecho a la portabilidad:</strong> Recibir sus datos en un formato estructurado y de uso común.</li>
                <li><strong>Derecho a retirar el consentimiento:</strong> Revocar su consentimiento en cualquier momento.</li>
              </ul>
              <p className="leading-relaxed">
                Para ejercer cualquiera de estos derechos, puede contactarnos a través del correo
                electrónico indicado en la sección de contacto.
              </p>
            </section>

            {/* Menores de edad */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                7. Menores de Edad
              </h2>
              <p className="leading-relaxed">
                La Aplicación no está dirigida a menores de 18 años. No recopilamos intencionalmente
                información personal de menores de edad. Si usted es padre o tutor y cree que su hijo
                nos ha proporcionado información personal, contáctenos para que podamos tomar las medidas necesarias.
              </p>
            </section>

            {/* Cambios a la política */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                8. Cambios a esta Política de Privacidad
              </h2>
              <p className="leading-relaxed">
                Podemos actualizar esta Política de Privacidad periódicamente. Le notificaremos
                cualquier cambio significativo a través de la Aplicación o por correo electrónico.
                La fecha de "Última actualización" al inicio de este documento indica cuándo se
                realizó la revisión más reciente. Le recomendamos revisar esta política periódicamente.
              </p>
            </section>

            {/* Ley aplicable */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                9. Ley Aplicable
              </h2>
              <p className="leading-relaxed">
                Esta Política de Privacidad se rige por las leyes de la República de Chile,
                particularmente la Ley N° 19.628 sobre Protección de la Vida Privada y sus modificaciones.
                Para usuarios de la Unión Europea, también cumplimos con las disposiciones aplicables del GDPR.
              </p>
            </section>

            {/* Contacto */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                10. Contacto
              </h2>
              <p className="leading-relaxed mb-4">
                Si tiene preguntas, inquietudes o desea ejercer sus derechos relacionados con
                esta Política de Privacidad, puede contactarnos a través de:
              </p>
              <div className="p-6 bg-muted/50 rounded-lg border border-border">
                <p className="mb-2"><strong>Desarrollador:</strong> drozast</p>
                <p className="mb-2"><strong>Aplicación:</strong> Frogio: Seguridad Municipal</p>
                <p className="mb-2">
                  <strong>Correo electrónico:</strong>{" "}
                  <a href={`mailto:${developerEmail}`} className="text-primary hover:underline">
                    {developerEmail}
                  </a>
                </p>
                <p><strong>País:</strong> Chile</p>
              </div>
              <p className="leading-relaxed mt-4">
                Nos comprometemos a responder a sus solicitudes en un plazo máximo de 30 días hábiles.
              </p>
            </section>
          </div>
        </article>
      </main>

      {/* Footer */}
      <footer className="border-t border-border py-8 mt-12">
        <div className="max-w-4xl mx-auto px-4 text-center text-sm text-muted-foreground">
          <p>&copy; {new Date().getFullYear()} Frogio. Todos los derechos reservados.</p>
        </div>
      </footer>
    </div>
  );
};

export default PrivacyPolicy;
