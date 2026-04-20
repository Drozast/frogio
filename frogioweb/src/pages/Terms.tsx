import { useEffect } from "react";
import { ArrowLeft } from "lucide-react";
import { Link } from "react-router-dom";

const Terms = () => {
  const lastUpdated = "19 de abril de 2026";
  const supportEmail = "rddigitalspa@gmail.com";

  useEffect(() => {
    document.title = "Términos y Condiciones - Frogio";
  }, []);

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
            Términos y Condiciones de Uso
          </h1>
          <p className="text-muted-foreground text-lg mb-8">
            Frogio: Seguridad Municipal
          </p>
          <p className="text-sm text-muted-foreground mb-8">
            Última actualización: {lastUpdated}
          </p>

          <div className="space-y-8 text-foreground/90">
            {/* 1. Aceptación */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                1. Aceptación de los Términos
              </h2>
              <p className="leading-relaxed mb-4">
                Al descargar, instalar o utilizar la aplicación móvil{" "}
                <strong>Frogio: Seguridad Municipal</strong> (en adelante, "la Aplicación"), usted
                (en adelante, "el Usuario") acepta quedar sujeto a estos Términos y Condiciones de
                Uso (en adelante, "los Términos"). Si no acepta estos Términos, no utilice la Aplicación.
              </p>
              <p className="leading-relaxed">
                Estos Términos constituyen un contrato legal vinculante entre el Usuario y{" "}
                <strong>drozast</strong> (en adelante, "el Desarrollador"), desarrollador de la Aplicación,
                operando en conjunto con la <strong>Municipalidad de Santa Juana</strong> (la "Municipalidad").
              </p>
            </section>

            {/* 2. Descripción del servicio */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                2. Descripción del Servicio
              </h2>
              <p className="leading-relaxed mb-4">
                Frogio es una plataforma de gestión municipal que permite a los ciudadanos:
              </p>
              <ul className="list-disc pl-6 space-y-2 mb-4">
                <li>Reportar denuncias y problemáticas de su comunidad.</li>
                <li>Enviar alertas de emergencia a inspectores municipales (botón SOS).</li>
                <li>Dar seguimiento al estado de sus reportes.</li>
              </ul>
              <p className="leading-relaxed">
                Los inspectores y administradores municipales utilizan la Aplicación para gestionar
                citaciones, fiscalizar, registrar el uso de vehículos municipales y responder a
                alertas ciudadanas.
              </p>
            </section>

            {/* 3. Aviso crítico SOS */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                3. Aviso Importante sobre Emergencias
              </h2>
              <p className="leading-relaxed mb-4 p-4 bg-red-500/5 border border-red-500/30 rounded-lg">
                <strong>
                  La Aplicación NO es un servicio oficial de emergencias. El botón SOS es un canal
                  complementario de notificación a inspectores municipales y NO reemplaza llamadas a
                  Carabineros (133), Bomberos (132) o SAMU (131).
                </strong>
                {" "}En situaciones de riesgo vital, llame siempre a los servicios oficiales de
                emergencia. El Desarrollador y la Municipalidad no se hacen responsables por
                demoras, fallas de red, falta de cobertura, batería del dispositivo o cualquier
                circunstancia que impida la transmisión oportuna de una alerta.
              </p>
            </section>

            {/* 4. Elegibilidad */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                4. Elegibilidad y Registro de Cuenta
              </h2>
              <ul className="list-disc pl-6 space-y-2">
                <li>
                  El Usuario debe ser mayor de 18 años o contar con el consentimiento de sus padres
                  o tutores legales.
                </li>
                <li>
                  El Usuario se compromete a proporcionar información veraz, exacta y actualizada
                  (nombre, RUT, correo electrónico, teléfono).
                </li>
                <li>
                  El Usuario es responsable de mantener la confidencialidad de sus credenciales
                  y de toda actividad que ocurra bajo su cuenta.
                </li>
                <li>
                  La suplantación de identidad está prohibida y puede ser denunciada a autoridades
                  competentes.
                </li>
              </ul>
            </section>

            {/* 5. Uso permitido */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                5. Uso Permitido
              </h2>
              <p className="leading-relaxed mb-4">
                El Usuario se compromete a utilizar la Aplicación exclusivamente para:
              </p>
              <ul className="list-disc pl-6 space-y-2 mb-4">
                <li>Reportar situaciones reales que afecten la seguridad o el bienestar de la comunidad.</li>
                <li>Activar el botón SOS solo en situaciones legítimas de emergencia o riesgo.</li>
                <li>Respetar la privacidad y dignidad de terceros en fotografías y descripciones.</li>
                <li>Cumplir con toda la legislación chilena aplicable.</li>
              </ul>
            </section>

            {/* 6. Usos prohibidos */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                6. Usos Prohibidos
              </h2>
              <p className="leading-relaxed mb-4">
                Queda estrictamente prohibido:
              </p>
              <ul className="list-disc pl-6 space-y-2">
                <li>
                  Presentar denuncias falsas, difamatorias o con el fin de perjudicar a terceros.
                  Las denuncias falsas pueden constituir delito de acuerdo al artículo 211 del
                  Código Penal chileno.
                </li>
                <li>Activar falsas alarmas SOS (puede constituir falta o delito).</li>
                <li>
                  Subir contenido ilícito, pornográfico, discriminatorio, violento, que infrinja
                  derechos de autor o vulnere la privacidad de terceros.
                </li>
                <li>Realizar ingeniería inversa, descompilar o extraer el código fuente.</li>
                <li>Acceder de forma no autorizada a cuentas, datos o sistemas de la Aplicación.</li>
                <li>Usar la Aplicación con fines comerciales no autorizados.</li>
                <li>Interferir con el funcionamiento de la Aplicación o sobrecargar los servidores.</li>
              </ul>
            </section>

            {/* 7. Propiedad intelectual */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                7. Propiedad Intelectual
              </h2>
              <p className="leading-relaxed mb-4">
                La Aplicación, su código, diseño, logos, marcas y contenido son propiedad del
                Desarrollador y están protegidos por la Ley N° 17.336 de Propiedad Intelectual de
                Chile y tratados internacionales.
              </p>
              <p className="leading-relaxed">
                El Usuario mantiene la propiedad de las fotografías, videos y textos que suba,
                pero otorga al Desarrollador y a la Municipalidad una licencia mundial, gratuita y
                no exclusiva para almacenar, procesar y mostrar dicho contenido con el propósito de
                operar el servicio.
              </p>
            </section>

            {/* 8. Disponibilidad */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                8. Disponibilidad del Servicio
              </h2>
              <p className="leading-relaxed">
                La Aplicación se ofrece "tal cual" y "según disponibilidad". El Desarrollador
                realizará esfuerzos razonables para mantener la Aplicación operativa pero no
                garantiza disponibilidad ininterrumpida, ausencia de errores, ni compatibilidad con
                todos los dispositivos. Podrán realizarse tareas de mantenimiento, actualizaciones
                o pausas que afecten temporalmente el servicio.
              </p>
            </section>

            {/* 9. Limitación de responsabilidad */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                9. Limitación de Responsabilidad
              </h2>
              <p className="leading-relaxed mb-4">
                En la máxima medida permitida por la ley chilena, el Desarrollador y la Municipalidad
                no serán responsables por:
              </p>
              <ul className="list-disc pl-6 space-y-2">
                <li>Daños indirectos, incidentales, consecuenciales o punitivos.</li>
                <li>Pérdida de datos, oportunidades o beneficios.</li>
                <li>Acciones u omisiones de terceros, incluidos otros Usuarios.</li>
                <li>Fallas de red, cobertura celular, servidores de terceros o del dispositivo del Usuario.</li>
                <li>Demoras o fallas en la transmisión de alertas SOS.</li>
                <li>Decisiones tomadas por el Usuario basadas en la información de la Aplicación.</li>
              </ul>
            </section>

            {/* 10. Suspensión y terminación */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                10. Suspensión y Terminación
              </h2>
              <p className="leading-relaxed">
                El Desarrollador puede suspender o cancelar la cuenta del Usuario, previa
                notificación razonable, si detecta incumplimiento de estos Términos, uso abusivo,
                actividad fraudulenta o solicitud de autoridades competentes. El Usuario puede
                eliminar su cuenta en cualquier momento siguiendo el procedimiento descrito en{" "}
                <Link to="/eliminacion" className="text-primary hover:underline">
                  /eliminacion
                </Link>.
              </p>
            </section>

            {/* 11. Notificaciones */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                11. Notificaciones y Permisos
              </h2>
              <p className="leading-relaxed">
                La Aplicación requiere permisos de ubicación, cámara, almacenamiento y notificaciones
                push para funcionar correctamente. El Usuario puede modificar estos permisos desde
                la configuración del dispositivo, entendiendo que algunas funcionalidades quedarán
                limitadas o no disponibles.
              </p>
            </section>

            {/* 12. Cambios */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                12. Cambios a los Términos
              </h2>
              <p className="leading-relaxed">
                El Desarrollador puede modificar estos Términos en cualquier momento. Los cambios
                significativos se comunicarán mediante la Aplicación o correo electrónico. El uso
                continuado de la Aplicación luego de la publicación constituye aceptación de los
                Términos modificados.
              </p>
            </section>

            {/* 13. Privacidad */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                13. Privacidad
              </h2>
              <p className="leading-relaxed">
                El tratamiento de datos personales se rige por nuestra{" "}
                <Link to="/privacidad" className="text-primary hover:underline">
                  Política de Privacidad
                </Link>
                , la cual forma parte integral de estos Términos.
              </p>
            </section>

            {/* 14. Ley aplicable */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                14. Ley Aplicable y Jurisdicción
              </h2>
              <p className="leading-relaxed">
                Estos Términos se rigen por las leyes de la República de Chile. Cualquier
                controversia se someterá a los tribunales ordinarios de justicia con asiento en
                Santa Juana, Región del Biobío, renunciando las partes a cualquier otro fuero.
              </p>
            </section>

            {/* 15. Contacto */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                15. Contacto
              </h2>
              <p className="leading-relaxed mb-4">
                Consultas, reclamos o solicitudes relacionadas con estos Términos pueden dirigirse a:
              </p>
              <div className="p-6 bg-muted/50 rounded-lg border border-border">
                <p className="mb-2"><strong>Desarrollador:</strong> drozast</p>
                <p className="mb-2"><strong>Aplicación:</strong> Frogio: Seguridad Municipal</p>
                <p className="mb-2">
                  <strong>Correo electrónico:</strong>{" "}
                  <a href={`mailto:${supportEmail}`} className="text-primary hover:underline">
                    {supportEmail}
                  </a>
                </p>
                <p><strong>País:</strong> Chile</p>
              </div>
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

export default Terms;
