import { useState, useEffect, useRef } from "react";
import { User, Shield, Settings, Check, Layers } from "lucide-react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import Modules from "./Modules";

const Profiles = () => {
  const [activeProfile, setActiveProfile] = useState(0);
  const [isVisible, setIsVisible] = useState(false);
  const sectionRef = useRef<HTMLElement>(null);

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting) {
          setIsVisible(true);
        }
      },
      { threshold: 0.2 }
    );

    if (sectionRef.current) {
      observer.observe(sectionRef.current);
    }

    return () => observer.disconnect();
  }, []);

  const profiles = [
    {
      icon: User,
      title: "Ciudadano",
      description: "El vecino que interactúa digitalmente con su municipalidad.",
      features: [
        "Reportar problemas con geolocalización",
        "Seguimiento en tiempo real de denuncias",
        "Botón de pánico para emergencias",
        "Historial personal de gestiones",
      ],
      gradient: "from-primary to-emerald-light",
      bgGradient: "from-primary/20 to-emerald-light/10",
      lightBg: "bg-primary/5",
    },
    {
      icon: Shield,
      title: "Inspector Municipal",
      description: "Funcionario de terreno que fiscaliza y atiende situaciones.",
      features: [
        "Mapa de denuncias activas",
        "Alertas de emergencia inmediatas",
        "Emisión de citaciones y advertencias",
        "Bitácora de vehículos municipales",
      ],
      gradient: "from-accent to-navy-light",
      bgGradient: "from-accent/20 to-navy-light/10",
      lightBg: "bg-accent/5",
    },
    {
      icon: Settings,
      title: "Administrador",
      description: "Gestión completa del sistema y supervisión de operaciones.",
      features: [
        "Configuración de usuarios y roles",
        "Dashboard de estadísticas",
        "Gestión de tipos de denuncia",
        "Control de fiscalización comunal",
      ],
      gradient: "from-violet-500 to-purple-600",
      bgGradient: "from-violet-500/20 to-purple-600/10",
      lightBg: "bg-violet-500/5",
    },
  ];

  return (
    <section
      id="profiles"
      ref={sectionRef}
      className="relative py-24 lg:py-32 bg-background overflow-hidden"
    >
      {/* Background decorations */}
      <div className="absolute inset-0 pointer-events-none">
        <div className="absolute top-1/4 -right-20 w-80 h-80 bg-gradient-to-br from-primary/10 to-transparent rounded-full blur-3xl" />
        <div className="absolute bottom-1/4 -left-20 w-64 h-64 bg-gradient-to-tr from-accent/10 to-transparent rounded-full blur-3xl" />
      </div>

      <div className="section-container relative z-10">
        {/* Tabs */}
        <Tabs defaultValue="perfiles" className="w-full">
          <div className={`flex justify-center mb-12 ${isVisible ? "animate-fade-in-down" : "opacity-0"}`}>
            <TabsList className="inline-flex h-14 items-center justify-center rounded-2xl bg-muted/50 p-1.5 backdrop-blur-sm border border-border/50">
              <TabsTrigger
                value="perfiles"
                className="inline-flex items-center gap-2 px-6 py-3 rounded-xl text-base font-medium data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-lg transition-all duration-300"
              >
                <User className="w-4 h-4" />
                Perfiles
              </TabsTrigger>
              <TabsTrigger
                value="modulos"
                className="inline-flex items-center gap-2 px-6 py-3 rounded-xl text-base font-medium data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-lg transition-all duration-300"
              >
                <Layers className="w-4 h-4" />
                Módulos
              </TabsTrigger>
            </TabsList>
          </div>

          <TabsContent value="perfiles" className="mt-0">
            {/* Header */}
            <div className={`text-center max-w-3xl mx-auto mb-16 ${isVisible ? "animate-fade-in-up" : "opacity-0"}`}>
              <h2 className="text-3xl md:text-4xl lg:text-5xl font-black text-foreground mb-6">
                Un sistema,{" "}
                <span className="bg-gradient-to-r from-primary via-accent to-violet-500 bg-clip-text text-transparent">
                  múltiples perfiles
                </span>
              </h2>
              <p className="text-lg lg:text-xl text-muted-foreground">
                Interfaces especializadas para cada actor del ecosistema municipal.
              </p>
            </div>

            {/* Profiles Grid */}
            <div className="grid lg:grid-cols-3 gap-6 lg:gap-8 mb-16">
              {profiles.map((profile, index) => (
                <div
                  key={profile.title}
                  className={`group relative rounded-3xl transition-all duration-500 cursor-pointer
                    ${isVisible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-8"}
                    ${activeProfile === index
                      ? `${profile.lightBg} border-2 border-primary/30 shadow-xl shadow-primary/5`
                      : "bg-slate border-2 border-transparent hover:border-primary/20"
                    }`}
                  style={{ transitionDelay: `${index * 0.15}s` }}
                  onMouseEnter={() => setActiveProfile(index)}
                >
                  {/* Gradient overlay on active */}
                  <div className={`absolute inset-0 bg-gradient-to-br ${profile.bgGradient} opacity-0 transition-opacity duration-500 rounded-3xl ${
                    activeProfile === index ? "opacity-100" : ""
                  }`} />

                  <div className="relative z-10 p-8">
                    {/* Icon */}
                    <div className={`relative w-16 h-16 rounded-2xl bg-gradient-to-br ${profile.gradient} p-[1px] mb-6 group-hover:scale-110 transition-transform duration-500`}>
                      <div className={`w-full h-full rounded-[15px] flex items-center justify-center transition-colors duration-300 ${
                        activeProfile === index ? "bg-transparent" : "bg-background"
                      }`}>
                        <profile.icon className={`w-8 h-8 transition-colors duration-300 ${
                          activeProfile === index ? "text-white" : "text-foreground"
                        }`} />
                      </div>
                      {/* Glow */}
                      <div className={`absolute inset-0 bg-gradient-to-br ${profile.gradient} blur-xl opacity-0 group-hover:opacity-40 transition-opacity duration-500 rounded-2xl`} />
                    </div>

                    {/* Title */}
                    <h3 className="text-2xl font-bold text-foreground mb-3">
                      {profile.title}
                    </h3>

                    {/* Description */}
                    <p className="text-muted-foreground mb-6">
                      {profile.description}
                    </p>

                    {/* Features */}
                    <ul className="space-y-3">
                      {profile.features.map((feature, fIndex) => (
                        <li
                          key={feature}
                          className="flex items-start gap-3"
                          style={{
                            transitionDelay: `${fIndex * 0.05}s`,
                          }}
                        >
                          <div className={`w-5 h-5 rounded-full bg-gradient-to-br ${profile.gradient} flex items-center justify-center flex-shrink-0 mt-0.5`}>
                            <Check className="w-3 h-3 text-white" />
                          </div>
                          <span className="text-sm text-foreground/80">{feature}</span>
                        </li>
                      ))}
                    </ul>

                    {/* Active indicator */}
                    <div className={`absolute bottom-4 right-4 w-3 h-3 rounded-full bg-gradient-to-br ${profile.gradient} transition-all duration-300 ${
                      activeProfile === index ? "opacity-100 scale-100" : "opacity-0 scale-0"
                    }`}>
                      <div className={`absolute inset-0 rounded-full bg-gradient-to-br ${profile.gradient} animate-ping opacity-75`} />
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {/* Interactive Preview Card */}
            <div className={`relative rounded-3xl bg-gradient-to-br from-slate to-slate-dark border border-border/50 p-8 lg:p-12 overflow-hidden ${
              isVisible ? "animate-scale-up" : "opacity-0"
            }`} style={{ animationDelay: "0.4s" }}>
              {/* Background decoration */}
              <div className="absolute inset-0 pointer-events-none">
                <div className={`absolute -top-20 -right-20 w-80 h-80 bg-gradient-to-br ${profiles[activeProfile].gradient} opacity-10 rounded-full blur-3xl transition-all duration-700`} />
                <div className="absolute inset-0 bg-grid-pattern opacity-20" />
              </div>

              <div className="relative z-10 flex flex-col lg:flex-row items-center gap-8">
                {/* Left content */}
                <div className="flex-1 text-center lg:text-left">
                  <div className={`inline-flex items-center gap-2 px-4 py-2 bg-gradient-to-r ${profiles[activeProfile].bgGradient} rounded-full mb-4`}>
                    <div className={`w-6 h-6 rounded-lg bg-gradient-to-br ${profiles[activeProfile].gradient} flex items-center justify-center`}>
                      {(() => {
                        const IconComponent = profiles[activeProfile].icon;
                        return <IconComponent className="w-4 h-4 text-white" />;
                      })()}
                    </div>
                    <span className="text-sm font-semibold text-foreground">
                      {profiles[activeProfile].title}
                    </span>
                  </div>
                  <h3 className="text-2xl lg:text-3xl font-bold text-foreground mb-4">
                    Interfaz adaptada a cada necesidad
                  </h3>
                  <p className="text-muted-foreground max-w-lg">
                    Cada perfil tiene acceso a funcionalidades específicas diseñadas para optimizar su flujo de trabajo y mejorar la eficiencia operativa.
                  </p>
                </div>

                {/* Right - Profile selector dots */}
                <div className="flex lg:flex-col gap-3">
                  {profiles.map((profile, index) => (
                    <button
                      key={profile.title}
                      onClick={() => setActiveProfile(index)}
                      className={`relative w-4 h-4 rounded-full transition-all duration-300 ${
                        activeProfile === index
                          ? `bg-gradient-to-br ${profile.gradient} scale-125`
                          : "bg-border hover:bg-muted-foreground/50"
                      }`}
                    >
                      {activeProfile === index && (
                        <div className={`absolute inset-0 rounded-full bg-gradient-to-br ${profile.gradient} animate-ping opacity-50`} />
                      )}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </TabsContent>

          <TabsContent value="modulos" className="mt-0">
            <Modules />
          </TabsContent>
        </Tabs>
      </div>
    </section>
  );
};

export default Profiles;
