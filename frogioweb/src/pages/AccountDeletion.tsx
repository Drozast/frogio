import { useEffect } from "react";
import { ArrowLeft, Mail, Clock, Trash2, Shield, AlertCircle } from "lucide-react";
import { Link } from "react-router-dom";

const AccountDeletion = () => {
  const supportEmail = "soporte@frogio.cl";

  useEffect(() => {
    document.title = "Eliminación de Cuenta - Frogio";
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
            Eliminación de Cuenta
          </h1>
          <p className="text-muted-foreground text-lg mb-8">
            Frogio: Seguridad Municipal
          </p>

          <div className="space-y-8 text-foreground/90">
            {/* Introducción */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                Derecho a la Eliminación de Datos
              </h2>
              <p className="leading-relaxed mb-4">
                En <strong>Frogio</strong>, respetamos tu derecho a la privacidad y al control de tus datos personales.
                De acuerdo con la Ley N° 19.628 sobre Protección de la Vida Privada de Chile y el Reglamento
                General de Protección de Datos (GDPR), tienes derecho a solicitar la eliminación completa
                de tu cuenta y los datos personales asociados.
              </p>
              <p className="leading-relaxed">
                Al eliminar tu cuenta, perderás acceso a todos los servicios de la aplicación Frogio,
                incluyendo el historial de denuncias y reportes realizados.
              </p>
            </section>

            {/* Pasos para solicitar eliminación */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                Cómo Solicitar la Eliminación de tu Cuenta
              </h2>
              <p className="leading-relaxed mb-6">
                Para solicitar la eliminación de tu cuenta y datos personales, sigue estos pasos:
              </p>

              <div className="space-y-4">
                {/* Paso 1 */}
                <div className="flex gap-4 p-4 bg-muted/30 rounded-lg border border-border">
                  <div className="flex-shrink-0 w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
                    <Mail className="w-5 h-5 text-primary" />
                  </div>
                  <div>
                    <h3 className="font-semibold text-foreground mb-1">Paso 1: Envía un correo electrónico</h3>
                    <p className="text-muted-foreground text-sm">
                      Escribe a{" "}
                      <a href={`mailto:${supportEmail}?subject=Solicitud%20de%20eliminación%20de%20cuenta`} className="text-primary hover:underline font-medium">
                        {supportEmail}
                      </a>
                      {" "}con el asunto: <strong>"Solicitud de eliminación de cuenta"</strong>
                    </p>
                  </div>
                </div>

                {/* Paso 2 */}
                <div className="flex gap-4 p-4 bg-muted/30 rounded-lg border border-border">
                  <div className="flex-shrink-0 w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
                    <span className="text-primary font-bold">@</span>
                  </div>
                  <div>
                    <h3 className="font-semibold text-foreground mb-1">Paso 2: Incluye tu información</h3>
                    <p className="text-muted-foreground text-sm">
                      En el cuerpo del correo, indica el <strong>email registrado en la aplicación Frogio</strong> para
                      que podamos identificar tu cuenta correctamente.
                    </p>
                  </div>
                </div>

                {/* Paso 3 */}
                <div className="flex gap-4 p-4 bg-muted/30 rounded-lg border border-border">
                  <div className="flex-shrink-0 w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
                    <Clock className="w-5 h-5 text-primary" />
                  </div>
                  <div>
                    <h3 className="font-semibold text-foreground mb-1">Paso 3: Espera la confirmación</h3>
                    <p className="text-muted-foreground text-sm">
                      Tu solicitud será procesada en un plazo máximo de <strong>30 días hábiles</strong>.
                      Recibirás un correo de confirmación una vez que la eliminación se haya completado.
                    </p>
                  </div>
                </div>
              </div>
            </section>

            {/* Datos que se eliminan */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4 flex items-center gap-2">
                <Trash2 className="w-5 h-5 text-red-500" />
                Datos que se Eliminan
              </h2>
              <p className="leading-relaxed mb-4">
                Al procesar tu solicitud de eliminación, se borrarán permanentemente los siguientes datos:
              </p>
              <ul className="space-y-3">
                <li className="flex items-start gap-3">
                  <span className="w-2 h-2 bg-red-500 rounded-full mt-2 flex-shrink-0"></span>
                  <span><strong>Información personal:</strong> Nombre completo, correo electrónico, RUT y número de teléfono.</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-2 h-2 bg-red-500 rounded-full mt-2 flex-shrink-0"></span>
                  <span><strong>Historial de denuncias:</strong> Todos los reportes y denuncias ciudadanas que hayas realizado.</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-2 h-2 bg-red-500 rounded-full mt-2 flex-shrink-0"></span>
                  <span><strong>Archivos multimedia:</strong> Fotografías, videos y documentos adjuntos a tus denuncias.</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-2 h-2 bg-red-500 rounded-full mt-2 flex-shrink-0"></span>
                  <span><strong>Datos de ubicación:</strong> Historial de ubicaciones asociadas a tus reportes.</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="w-2 h-2 bg-red-500 rounded-full mt-2 flex-shrink-0"></span>
                  <span><strong>Preferencias y configuración:</strong> Ajustes de notificaciones y preferencias de la app.</span>
                </li>
              </ul>
            </section>

            {/* Datos que se conservan */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4 flex items-center gap-2">
                <Shield className="w-5 h-5 text-amber-500" />
                Datos que se Conservan por Obligación Legal
              </h2>
              <p className="leading-relaxed mb-4">
                De acuerdo con las obligaciones legales vigentes en Chile, algunos registros deben conservarse
                por un período determinado, incluso después de la eliminación de tu cuenta:
              </p>
              <div className="p-4 bg-amber-500/10 border border-amber-500/20 rounded-lg">
                <p className="text-foreground/90">
                  <strong>Registros de auditoría:</strong> Se conservarán por un período de <strong>1 año</strong>
                  para cumplir con requisitos legales y de seguridad. Estos registros <strong>no contienen
                  información personal identificable</strong> y se utilizan únicamente para fines de auditoría del sistema.
                </p>
              </div>
            </section>

            {/* Advertencia */}
            <section>
              <div className="p-4 bg-red-500/10 border border-red-500/20 rounded-lg flex gap-4">
                <AlertCircle className="w-6 h-6 text-red-500 flex-shrink-0 mt-0.5" />
                <div>
                  <h3 className="font-semibold text-foreground mb-2">Importante</h3>
                  <p className="text-foreground/80 text-sm">
                    La eliminación de cuenta es <strong>irreversible</strong>. Una vez procesada la solicitud,
                    no será posible recuperar los datos eliminados. Si deseas volver a utilizar Frogio en el futuro,
                    deberás crear una nueva cuenta.
                  </p>
                </div>
              </div>
            </section>

            {/* Contacto */}
            <section>
              <h2 className="text-xl font-semibold text-foreground mb-4">
                Contacto
              </h2>
              <p className="leading-relaxed mb-4">
                Si tienes preguntas sobre el proceso de eliminación de cuenta o necesitas asistencia adicional,
                puedes contactarnos a través de:
              </p>
              <div className="p-6 bg-muted/50 rounded-lg border border-border">
                <p className="mb-2"><strong>Aplicación:</strong> Frogio: Seguridad Municipal</p>
                <p className="mb-2">
                  <strong>Correo de soporte:</strong>{" "}
                  <a href={`mailto:${supportEmail}`} className="text-primary hover:underline">
                    {supportEmail}
                  </a>
                </p>
                <p className="mb-2"><strong>Tiempo de respuesta:</strong> Máximo 30 días hábiles</p>
                <p><strong>País:</strong> Chile</p>
              </div>
            </section>

            {/* Link a privacidad */}
            <section className="pt-4">
              <p className="text-muted-foreground">
                Para más información sobre cómo manejamos tus datos, consulta nuestra{" "}
                <Link to="/privacidad" className="text-primary hover:underline font-medium">
                  Política de Privacidad
                </Link>.
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

export default AccountDeletion;
