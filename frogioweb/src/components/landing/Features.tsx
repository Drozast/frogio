import { useEffect, useRef, useState } from "react";
import {
  AlertTriangle,
  MapPin,
  Camera,
  Bell,
  FileText,
  BarChart3,
  Users,
  Car,
  ClipboardCheck,
  Zap
} from "lucide-react";

const Features = () => {
  const [visibleCards, setVisibleCards] = useState<Set<number>>(new Set());
  const sectionRef = useRef<HTMLElement>(null);

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const index = Number(entry.target.getAttribute("data-index"));
            setVisibleCards((prev) => new Set([...prev, index]));
          }
        });
      },
      { threshold: 0.2, rootMargin: "0px 0px -50px 0px" }
    );

    const cards = sectionRef.current?.querySelectorAll("[data-index]");
    cards?.forEach((card) => observer.observe(card));

    return () => observer.disconnect();
  }, []);

  const features = [
    {
      icon: AlertTriangle,
      title: "Botón de Pánico",
      description: "Alerta de emergencia con ubicación GPS en tiempo real para situaciones de peligro.",
      gradient: "from-red-500 to-orange-500",
      bgGradient: "from-red-500/10 to-orange-500/10",
    },
    {
      icon: MapPin,
      title: "Geolocalización",
      description: "Denuncias con ubicación exacta y mapa interactivo para una respuesta precisa.",
      gradient: "from-primary to-emerald-light",
      bgGradient: "from-primary/10 to-emerald-light/10",
    },
    {
      icon: Camera,
      title: "Evidencia Fotográfica",
      description: "Adjunta fotos para documentar problemas y agilizar la gestión municipal.",
      gradient: "from-violet-500 to-purple-500",
      bgGradient: "from-violet-500/10 to-purple-500/10",
    },
    {
      icon: Bell,
      title: "Notificaciones Push",
      description: "Actualizaciones automáticas sobre el estado de denuncias y alertas.",
      gradient: "from-cyan-500 to-blue-500",
      bgGradient: "from-cyan-500/10 to-blue-500/10",
    },
    {
      icon: FileText,
      title: "Citaciones Digitales",
      description: "Emisión de citaciones formales a personas, vehículos o comercios.",
      gradient: "from-amber-500 to-yellow-500",
      bgGradient: "from-amber-500/10 to-yellow-500/10",
    },
    {
      icon: BarChart3,
      title: "Dashboard Analytics",
      description: "Estadísticas y métricas en tiempo real para la toma de decisiones.",
      gradient: "from-primary to-teal-500",
      bgGradient: "from-primary/10 to-teal-500/10",
    },
    {
      icon: Users,
      title: "Multi-perfil",
      description: "Interfaces adaptadas para ciudadanos, inspectores y administradores.",
      gradient: "from-pink-500 to-rose-500",
      bgGradient: "from-pink-500/10 to-rose-500/10",
    },
    {
      icon: Car,
      title: "Control de Flota",
      description: "Bitácora de vehículos municipales con control de kilometraje y GPS.",
      gradient: "from-indigo-500 to-blue-500",
      bgGradient: "from-indigo-500/10 to-blue-500/10",
    },
    {
      icon: ClipboardCheck,
      title: "Seguimiento Completo",
      description: "Trazabilidad de cada denuncia desde su creación hasta su resolución.",
      gradient: "from-emerald-light to-primary",
      bgGradient: "from-emerald-light/10 to-primary/10",
    },
  ];

  return (
    <section
      id="features"
      ref={sectionRef}
      className="relative py-24 lg:py-32 bg-slate overflow-hidden"
    >
      {/* Background decorations */}
      <div className="absolute inset-0 pointer-events-none">
        <div className="absolute top-20 left-10 w-72 h-72 bg-primary/5 rounded-full blur-3xl" />
        <div className="absolute bottom-20 right-10 w-96 h-96 bg-emerald-light/5 rounded-full blur-3xl" />
        <div className="absolute inset-0 bg-grid-pattern opacity-30" />
      </div>

      <div className="section-container relative z-10">
        {/* Header */}
        <div className="text-center max-w-3xl mx-auto mb-20">
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-primary/10 border border-primary/20 rounded-full mb-6 animate-fade-in-down">
            <Zap className="w-4 h-4 text-primary" />
            <span className="text-sm font-semibold text-primary">Funcionalidades Poderosas</span>
          </div>
          <h2 className="text-3xl md:text-4xl lg:text-5xl font-black text-foreground mb-6 animate-fade-in-up">
            Todo lo que tu municipio{" "}
            <span className="bg-gradient-to-r from-primary via-emerald-light to-teal-500 bg-clip-text text-transparent">
              necesita
            </span>
          </h2>
          <p className="text-lg lg:text-xl text-muted-foreground animate-fade-in-up" style={{ animationDelay: "0.1s" }}>
            Una plataforma integral que moderniza la comunicación entre ciudadanos y municipalidades.
          </p>
        </div>

        {/* Features Grid */}
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6 lg:gap-8">
          {features.map((feature, index) => (
            <div
              key={feature.title}
              data-index={index}
              className={`group relative bg-background p-6 lg:p-8 rounded-3xl border border-border/50 transition-all duration-500 cursor-default
                ${visibleCards.has(index)
                  ? "opacity-100 translate-y-0"
                  : "opacity-0 translate-y-8"
                }
                hover:border-primary/30 hover:-translate-y-2 hover:shadow-2xl hover:shadow-primary/5`}
              style={{
                transitionDelay: `${index * 0.1}s`,
              }}
            >
              {/* Gradient background on hover */}
              <div className={`absolute inset-0 bg-gradient-to-br ${feature.bgGradient} opacity-0 group-hover:opacity-100 transition-opacity duration-500 rounded-3xl`} />

              {/* Content */}
              <div className="relative z-10">
                {/* Icon */}
                <div className={`relative w-14 h-14 rounded-2xl bg-gradient-to-br ${feature.gradient} p-[1px] mb-6 group-hover:scale-110 group-hover:rotate-3 transition-all duration-500`}>
                  <div className="w-full h-full bg-background rounded-[15px] flex items-center justify-center group-hover:bg-transparent transition-colors duration-300">
                    <feature.icon className="w-7 h-7 text-foreground group-hover:text-white transition-colors duration-300" />
                  </div>
                  {/* Glow effect */}
                  <div className={`absolute inset-0 bg-gradient-to-br ${feature.gradient} blur-xl opacity-0 group-hover:opacity-50 transition-opacity duration-500 rounded-2xl`} />
                </div>

                {/* Title */}
                <h3 className="text-xl font-bold text-foreground mb-3 group-hover:text-primary transition-colors duration-300">
                  {feature.title}
                </h3>

                {/* Description */}
                <p className="text-muted-foreground leading-relaxed group-hover:text-foreground/80 transition-colors duration-300">
                  {feature.description}
                </p>

                {/* Arrow indicator */}
                <div className="mt-6 flex items-center gap-2 text-primary opacity-0 group-hover:opacity-100 transition-all duration-300 transform translate-x-0 group-hover:translate-x-2">
                  <span className="text-sm font-semibold">Saber más</span>
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
                  </svg>
                </div>
              </div>

              {/* Corner decoration */}
              <div className={`absolute top-4 right-4 w-20 h-20 bg-gradient-to-br ${feature.gradient} opacity-5 rounded-full blur-2xl group-hover:opacity-20 transition-opacity duration-500`} />
            </div>
          ))}
        </div>

        {/* Bottom CTA */}
        <div className="text-center mt-16 animate-fade-in-up" style={{ animationDelay: "0.5s" }}>
          <p className="text-muted-foreground mb-4">
            ¿Quieres ver todas las funcionalidades en acción?
          </p>
          <a
            href="#contact"
            className="inline-flex items-center gap-2 text-primary font-semibold hover:gap-4 transition-all duration-300"
          >
            Agenda una demo personalizada
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
            </svg>
          </a>
        </div>
      </div>
    </section>
  );
};

export default Features;
