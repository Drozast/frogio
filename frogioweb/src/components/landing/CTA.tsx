import { ArrowRight, Mail, Phone, Sparkles, MessageCircle, Calendar } from "lucide-react";
import { Button } from "@/components/ui/button";

const CTA = () => {
  return (
    <section id="contact" className="relative py-24 lg:py-32 overflow-hidden">
      {/* Animated gradient background */}
      <div className="absolute inset-0 bg-gradient-to-br from-accent via-navy to-accent bg-[length:400%_400%] animate-gradient-xy" />

      {/* Overlay pattern */}
      <div className="absolute inset-0 bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHZpZXdCb3g9IjAgMCA2MCA2MCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48ZyBmaWxsPSJub25lIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiPjxnIGZpbGw9IiNmZmZmZmYiIGZpbGwtb3BhY2l0eT0iMC4wMyI+PGNpcmNsZSBjeD0iMzAiIGN5PSIzMCIgcj0iMiIvPjwvZz48L2c+PC9zdmc+')] opacity-50" />

      {/* Decorative elements */}
      <div className="absolute inset-0 pointer-events-none overflow-hidden">
        {/* Glowing orbs */}
        <div className="absolute -top-20 -left-20 w-80 h-80 bg-primary/20 rounded-full blur-3xl animate-float" />
        <div className="absolute -bottom-20 -right-20 w-96 h-96 bg-emerald-light/15 rounded-full blur-3xl animate-float" style={{ animationDelay: '2s' }} />
        <div className="absolute top-1/2 left-1/4 w-64 h-64 bg-cyan-400/10 rounded-full blur-3xl animate-float-slow" />

        {/* Floating shapes */}
        <div className="absolute top-20 right-1/4 w-16 h-16 border-2 border-white/10 rounded-2xl rotate-12 animate-float" style={{ animationDelay: '1s' }} />
        <div className="absolute bottom-20 left-1/4 w-12 h-12 border-2 border-white/10 rounded-full animate-float" style={{ animationDelay: '3s' }} />
        <div className="absolute top-1/3 right-20 w-8 h-8 bg-primary/20 rounded-lg rotate-45 animate-morph" />
      </div>

      <div className="section-container relative z-10">
        <div className="max-w-4xl mx-auto">
          {/* Main content */}
          <div className="text-center mb-12">
            {/* Badge */}
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-white/10 backdrop-blur-sm border border-white/20 rounded-full mb-8 animate-fade-in-down">
              <Sparkles className="w-4 h-4 text-primary animate-pulse" />
              <span className="text-sm font-medium text-white/90">Transforma tu municipio hoy</span>
            </div>

            {/* Headline */}
            <h2 className="text-4xl md:text-5xl lg:text-6xl font-black text-white mb-6 animate-fade-in-up leading-tight">
              Moderniza tu municipio{" "}
              <span className="relative">
                <span className="bg-gradient-to-r from-primary via-emerald-light to-teal-400 bg-clip-text text-transparent">
                  hoy
                </span>
                <svg className="absolute -bottom-2 left-0 w-full" viewBox="0 0 100 8" fill="none">
                  <path
                    d="M0 5C25 2 75 2 100 5"
                    stroke="currentColor"
                    strokeWidth="3"
                    strokeLinecap="round"
                    className="text-primary/60"
                  />
                </svg>
              </span>
            </h2>

            {/* Description */}
            <p className="text-lg lg:text-xl text-white/70 mb-10 max-w-2xl mx-auto animate-fade-in-up" style={{ animationDelay: '0.1s' }}>
              Únete a los municipios que ya están transformando la gestión ciudadana con FROGIO.
              Agenda una demo gratuita y descubre el futuro de la administración municipal.
            </p>
          </div>

          {/* CTA Buttons */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center mb-16 animate-fade-in-up" style={{ animationDelay: '0.2s' }}>
            <Button
              size="lg"
              className="group relative bg-white text-accent hover:bg-white/90 font-bold px-10 h-16 text-lg shadow-2xl shadow-black/20 overflow-hidden transition-all duration-500 hover:scale-105"
            >
              <span className="relative z-10 flex items-center gap-3">
                <Calendar className="w-5 h-5" />
                Solicitar Demo Gratuita
                <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
              </span>
              {/* Shimmer */}
              <div className="absolute inset-0 -translate-x-full group-hover:translate-x-full transition-transform duration-1000 bg-gradient-to-r from-transparent via-primary/20 to-transparent" />
            </Button>

            <Button
              size="lg"
              variant="outline"
              className="group border-2 border-white/30 bg-white/5 backdrop-blur-sm text-white hover:bg-white/10 hover:border-white/50 font-medium px-8 h-16 text-lg transition-all duration-300"
            >
              <MessageCircle className="w-5 h-5 mr-2" />
              Hablar con ventas
            </Button>
          </div>

          {/* Contact cards */}
          <div className="grid sm:grid-cols-2 gap-6 max-w-2xl mx-auto animate-fade-in-up" style={{ animationDelay: '0.3s' }}>
            {/* Email card */}
            <a
              href="mailto:rddigitalspa@gmail.com"
              className="group flex items-center gap-4 p-6 bg-white/5 backdrop-blur-sm border border-white/10 rounded-2xl hover:bg-white/10 hover:border-white/20 transition-all duration-300 hover:-translate-y-1"
            >
              <div className="w-14 h-14 bg-gradient-to-br from-primary to-emerald-light rounded-xl flex items-center justify-center group-hover:scale-110 transition-transform duration-300">
                <Mail className="w-6 h-6 text-white" />
              </div>
              <div>
                <p className="text-sm text-white/60 mb-1">Escríbenos</p>
                <p className="text-lg font-semibold text-white group-hover:text-primary transition-colors">
                  rddigitalspa@gmail.com
                </p>
              </div>
            </a>

            {/* Phone card */}
            <a
              href="tel:+56912345678"
              className="group flex items-center gap-4 p-6 bg-white/5 backdrop-blur-sm border border-white/10 rounded-2xl hover:bg-white/10 hover:border-white/20 transition-all duration-300 hover:-translate-y-1"
            >
              <div className="w-14 h-14 bg-gradient-to-br from-cyan-500 to-blue-500 rounded-xl flex items-center justify-center group-hover:scale-110 transition-transform duration-300">
                <Phone className="w-6 h-6 text-white" />
              </div>
              <div>
                <p className="text-sm text-white/60 mb-1">Llámanos</p>
                <p className="text-lg font-semibold text-white group-hover:text-primary transition-colors">
                  +56 9 1234 5678
                </p>
              </div>
            </a>
          </div>

          {/* Trust badges */}
          <div className="flex flex-wrap justify-center gap-8 mt-16 pt-12 border-t border-white/10 animate-fade-in-up" style={{ animationDelay: '0.4s' }}>
            {[
              { value: "50+", label: "Municipios" },
              { value: "100K+", label: "Usuarios" },
              { value: "99.9%", label: "Uptime" },
              { value: "24/7", label: "Soporte" },
            ].map((stat, index) => (
              <div key={stat.label} className="text-center group cursor-default" style={{ animationDelay: `${0.5 + index * 0.1}s` }}>
                <p className="text-3xl lg:text-4xl font-black text-white mb-1 group-hover:text-primary transition-colors">
                  {stat.value}
                </p>
                <p className="text-sm text-white/60">{stat.label}</p>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Bottom wave */}
      <div className="absolute bottom-0 left-0 right-0">
        <svg className="w-full h-24 fill-background" viewBox="0 0 1440 100" preserveAspectRatio="none">
          <path d="M0,50 C360,100 720,0 1080,50 C1260,75 1380,75 1440,50 L1440,100 L0,100 Z" />
        </svg>
      </div>
    </section>
  );
};

export default CTA;
