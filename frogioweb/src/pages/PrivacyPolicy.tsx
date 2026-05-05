import { ArrowLeft } from "lucide-react";
import { Link } from "react-router-dom";

const PrivacyPolicy = () => {
  const lastUpdated = "5 de mayo de 2026";
  const developerEmail = "rddigitalspa@gmail.com";

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
                6. Sus Derechos (Derechos ARCOP)
              </h2>
              <p className="leading-relaxed mb-4">
                De acuerdo con la <strong>Ley N° 21.719</strong> que regula la protección y el tratamiento
                de los datos personales en Chile (publicada en diciembre de 2024 y plenamente vigente
                desde diciembre de 2026), la <strong>Ley N° 19.628</strong> sobre Protección de la Vida
                Privada y el Reglamento General de Protección de Datos (GDPR) de la Unión Europea,
                usted como titular de datos tiene los siguientes derechos —conocidos en Chile como
                derechos <strong>ARCOP</strong>— que puede ejercer en cualquier momento y de forma gratuita:
              </p>
              <ul className="list-disc pl-6 space-y-2 mb-6">
                <li><strong>Derecho de acceso:</strong> Solicitar información sobre los datos personales que tratamos sobre usted, su origen y la finalidad del tratamiento.</li>
                <li><strong>Derecho de rectificación:</strong> Corregir datos inexactos, incompletos o desactualizados.</li>
                <li><strong>Derecho de cancelación/supresión:</strong> Solicitar la eliminación de sus datos personales cuando ya no sean necesarios o haya retirado su consentimiento.</li>
                <li><strong>Derecho de oposición:</strong> Oponerse al tratamiento de sus datos para fines específicos, salvo cuando exista una obligación legal.</li>
                <li><strong>Derecho a la portabilidad:</strong> Recibir sus datos en un formato estructurado, de uso común y lectura mecánica, o solicitar su transferencia a otro responsable.</li>
                <li><strong>Derecho de bloqueo:</strong> Solicitar la suspensión temporal del tratamiento de sus datos mientras se resuelve una controversia sobre su exactitud o licitud.</li>
                <li><strong>Derecho a retirar el consentimiento:</strong> Revocar su consentimiento en cualquier momento, sin que ello afecte la licitud del tratamiento previo.</li>
                <li><strong>Derecho a no ser objeto de decisiones automatizadas:</strong> No ser sometido a decisiones basadas únicamente en tratamientos automatizados que produzcan efectos jurídicos sobre usted.</li>
                <li><strong>Derecho a reclamar ante la Agencia de Protección de Datos Personales:</strong> Presentar reclamos cuando considere que se han vulnerado sus derechos (autoridad de control creada por la Ley 21.719).</li>
              </ul>
              <p className="leading-relaxed mb-4">
                Para ejercer cualquiera de estos derechos, puede contactarnos a través del correo
                electrónico indicado en la sección de contacto. Nos comprometemos a responder dentro
                de los plazos que establece la legislación vigente.
              </p>
              <p className="leading-relaxed p-4 bg-primary/5 border border-primary/20 rounded-lg">
                <strong>Base de licitud del tratamiento:</strong> tratamos sus datos personales con
                base en (i) su consentimiento libre, específico, informado e inequívoco al registrarse
                en la Aplicación; (ii) el cumplimiento de obligaciones legales municipales; (iii) el
                interés público en materia de seguridad ciudadana; y (iv) la protección de intereses
                vitales en situaciones de emergencia (botón SOS).
              </p>
            </section>

            {/* Ley 21.719 — Cumplimiento específico */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                6 bis. Cumplimiento de la Ley N° 21.719 de Protección de Datos Personales
              </h2>
              <p className="leading-relaxed mb-4">
                La Ley N° 21.719, publicada en el Diario Oficial el 13 de diciembre de 2024, moderniza
                el marco chileno de protección de datos personales y entrará en plena vigencia el
                <strong> 1 de diciembre de 2026</strong>. Frogio adopta los siguientes principios y
                medidas para dar cumplimiento a esta normativa:
              </p>
              <ul className="list-disc pl-6 space-y-2 mb-4">
                <li>
                  <strong>Principio de licitud, lealtad y transparencia:</strong> tratamos sus datos
                  conforme a la ley, informándole de manera clara y oportuna sobre el uso que les damos.
                </li>
                <li>
                  <strong>Principio de finalidad:</strong> los datos se recopilan para finalidades
                  específicas, explícitas y lícitas (gestión de denuncias, seguridad ciudadana,
                  alertas de emergencia) y no son tratados de manera incompatible con dichos fines.
                </li>
                <li>
                  <strong>Principio de proporcionalidad y minimización:</strong> recopilamos sólo los
                  datos estrictamente necesarios para las finalidades indicadas.
                </li>
                <li>
                  <strong>Principio de calidad:</strong> mantenemos los datos exactos, completos y
                  actualizados; usted puede solicitar correcciones en cualquier momento.
                </li>
                <li>
                  <strong>Principio de responsabilidad (accountability):</strong> documentamos el
                  tratamiento de datos y adoptamos medidas técnicas y organizativas para demostrar
                  cumplimiento.
                </li>
                <li>
                  <strong>Principio de seguridad:</strong> implementamos cifrado en tránsito y en
                  reposo, control de accesos y registros de auditoría.
                </li>
                <li>
                  <strong>Principio de confidencialidad:</strong> el personal autorizado está sujeto
                  a deber de secreto respecto de los datos personales tratados.
                </li>
                <li>
                  <strong>Datos sensibles:</strong> el tratamiento de categorías especiales de datos
                  (por ejemplo, ubicación en tiempo real durante una emergencia) se realiza con su
                  consentimiento expreso o cuando resulte indispensable para proteger su vida o salud.
                </li>
                <li>
                  <strong>Notificación de brechas de seguridad:</strong> en caso de una vulneración
                  que afecte sus datos personales, le notificaremos a usted y a la Agencia de Protección
                  de Datos Personales en los plazos que establezca la ley.
                </li>
                <li>
                  <strong>Transferencias internacionales:</strong> cualquier transferencia de datos
                  fuera de Chile se realizará a países o proveedores que ofrezcan un nivel adecuado
                  de protección, conforme a los criterios de la Ley 21.719.
                </li>
              </ul>
              <p className="leading-relaxed">
                <strong>Responsable del tratamiento:</strong> drozast (correo de contacto en la
                sección 10). En caso de discrepancia con nuestra respuesta, usted puede presentar un
                reclamo ante la <strong>Agencia de Protección de Datos Personales</strong>, autoridad
                de control creada por la Ley N° 21.719.
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
                particularmente la <strong>Ley N° 21.719 que regula la protección y tratamiento
                de los datos personales</strong> (publicada el 13 de diciembre de 2024 y plenamente
                vigente desde el 1 de diciembre de 2026), la <strong>Ley N° 19.628 sobre Protección
                de la Vida Privada</strong> y sus modificaciones. Para usuarios de la Unión Europea,
                también cumplimos con las disposiciones aplicables del Reglamento General de
                Protección de Datos (GDPR).
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
