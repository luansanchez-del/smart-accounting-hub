import { createFileRoute } from "@tanstack/react-router";
import {
  ArrowRight,
  ArrowUpRight,
  Sparkles,
  Check,
  Landmark,
  FileText,
  BarChart3,
  Receipt,
  BellRing,
  Workflow,
  ShieldCheck,
  Bot,
  LineChart,
  Quote,
  Menu,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Numera — Contabilidade Inteligente e Automação" },
      {
        name: "description",
        content:
          "Plataforma de contabilidade inteligente que automatiza conciliação bancária, notas fiscais, fiscal e relatórios para escritórios e empresas.",
      },
      {
        property: "og:title",
        content: "Numera — Contabilidade Inteligente e Automação",
      },
      {
        property: "og:description",
        content:
          "Automatize conciliação, emissão de notas, fiscal e relatórios. Contabilidade inteligente que trabalha por você.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: Index,
});

function Logo({ className = "" }: { className?: string }) {
  return (
    <div className={`flex items-center gap-2.5 ${className}`}>
      <div className="relative grid h-9 w-9 place-items-center rounded-xl bg-primary text-primary-foreground shadow-sm">
        <span className="font-display text-lg font-bold leading-none">N</span>
        <span className="absolute -right-1 -top-1 h-3 w-3 rounded-full bg-gold ring-2 ring-background" />
      </div>
      <span className="font-display text-xl font-semibold tracking-tight text-foreground">
        Numera
      </span>
    </div>
  );
}

function Navbar() {
  const links = [
    { label: "Recursos", href: "#recursos" },
    { label: "Como funciona", href: "#como-funciona" },
    { label: "Plataforma", href: "#plataforma" },
    { label: "Preços", href: "#precos" },
    { label: "FAQ", href: "#faq" },
  ];
  return (
    <header className="sticky top-0 z-50 border-b border-border/70 bg-background/80 backdrop-blur-xl">
      <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-5 sm:px-8">
        <Logo />
        <nav className="hidden items-center gap-8 md:flex">
          {links.map((l) => (
            <a
              key={l.href}
              href={l.href}
              className="text-sm font-medium text-muted-foreground transition-colors hover:text-foreground"
            >
              {l.label}
            </a>
          ))}
        </nav>
        <div className="hidden items-center gap-3 md:flex">
          <a
            href="#login"
            className="text-sm font-medium text-muted-foreground transition-colors hover:text-foreground"
          >
            Entrar
          </a>
          <Button asChild className="btn-primary-glow">
            <a href="#precos">
              Começar grátis
              <ArrowRight className="ml-1.5 h-4 w-4" />
            </a>
          </Button>
        </div>
        <Button variant="outline" size="icon" className="md:hidden">
          <Menu className="h-5 w-5" />
        </Button>
      </div>
    </header>
  );
}

function Hero() {
  return (
    <section className="relative overflow-hidden">
      <div className="absolute inset-0 hero-mesh" aria-hidden />
      <div className="absolute inset-0 grid-lines opacity-60" aria-hidden />
      <div className="relative mx-auto max-w-7xl px-5 pt-16 pb-12 sm:px-8 sm:pt-24">
        <div className="mx-auto max-w-3xl text-center">
          <div className="animate-rise flex justify-center">
            <Badge
              variant="secondary"
              className="gap-1.5 rounded-full border-border bg-secondary/80 px-3.5 py-1.5 text-xs font-medium backdrop-blur"
            >
              <Sparkles className="h-3.5 w-3.5 text-primary" />
              Novo · Automação bancária em tempo real
            </Badge>
          </div>
          <h1 className="animate-rise mt-6 text-balance text-4xl font-semibold leading-[1.05] text-foreground sm:text-6xl">
            Contabilidade inteligente que{" "}
            <span className="relative whitespace-nowrap text-primary">
              trabalha por você
              <svg
                className="absolute -bottom-2 left-0 w-full text-gold"
                viewBox="0 0 300 12"
                fill="none"
                preserveAspectRatio="none"
                aria-hidden
              >
                <path
                  d="M2 9C60 3 180 3 298 8"
                  stroke="currentColor"
                  strokeWidth="3.5"
                  strokeLinecap="round"
                />
              </svg>
            </span>
          </h1>
          <p className="animate-rise mx-auto mt-7 max-w-2xl text-balance text-lg text-muted-foreground">
            A Numera automatiza conciliação, emissão de notas, fechamento fiscal
            e relatórios. Seu escritório ganha tempo, reduz erros e opera com
            dados sempre atualizados.
          </p>
          <div className="animate-rise mt-9 flex flex-col items-center justify-center gap-3 sm:flex-row">
            <Button asChild size="lg" className="btn-primary-glow w-full sm:w-auto">
              <a href="#precos">
                Começar grátis
                <ArrowRight className="ml-2 h-4 w-4" />
              </a>
            </Button>
            <Button asChild size="lg" variant="outline" className="w-full sm:w-auto">
              <a href="#plataforma">
                Ver plataforma
                <ArrowUpRight className="ml-2 h-4 w-4" />
              </a>
            </Button>
          </div>
          <p className="mt-4 text-xs text-muted-foreground">
            14 dias grátis · sem cartão · cancele quando quiser
          </p>
        </div>
        <HeroDashboard />
      </div>
    </section>
  );
}

function HeroDashboard() {
  const bars = [42, 58, 35, 70, 52, 84, 64, 92];
  return (
    <div className="animate-rise mt-14">
      <div className="card-elevated relative mx-auto max-w-5xl overflow-hidden rounded-3xl p-3">
        <div className="rounded-2xl border border-border bg-background p-5 sm:p-6">
          {/* window bar */}
          <div className="mb-5 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="h-2.5 w-2.5 rounded-full bg-destructive/70" />
              <span className="h-2.5 w-2.5 rounded-full bg-gold/80" />
              <span className="h-2.5 w-2.5 rounded-full bg-primary/80" />
              <span className="ml-3 text-xs font-medium text-muted-foreground">
                numera.app/painel
              </span>
            </div>
            <Badge className="rounded-full bg-primary/10 text-primary hover:bg-primary/10">
              <span className="mr-1 h-1.5 w-1.5 animate-pulse rounded-full bg-primary" />
              Ao vivo
            </Badge>
          </div>
          {/* kpis */}
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            {[
              { k: "Conciliação automática", v: "93%", s: "+12% mês" },
              { k: "Lançamentos hoje", v: "1.248", s: "IA · 99,8% acerto" },
              { k: "Tempo economizado", v: "41h", s: "por mês" },
              { k: "Tarefas em fila", v: "0", s: "tudo em dia" },
            ].map((m) => (
              <div
                key={m.k}
                className="rounded-xl border border-border bg-muted/40 p-3.5"
              >
                <p className="text-[11px] font-medium text-muted-foreground">
                  {m.k}
                </p>
                <p className="mt-1.5 font-display text-2xl font-semibold text-foreground">
                  {m.v}
                </p>
                <p className="mt-0.5 text-[11px] text-primary">{m.s}</p>
              </div>
            ))}
          </div>
          {/* chart + feed */}
          <div className="mt-3 grid gap-3 lg:grid-cols-5">
            <div className="rounded-xl border border-border bg-muted/30 p-4 lg:col-span-3">
              <div className="mb-4 flex items-center justify-between">
                <div className="flex items-center gap-2 text-sm font-medium text-foreground">
                  <BarChart3 className="h-4 w-4 text-primary" />
                  Fluxo de caixa automatizado
                </div>
                <span className="text-xs text-muted-foreground">Últimos 8 ciclos</span>
              </div>
              <div className="flex h-32 items-stretch gap-2.5">
                {bars.map((h, i) => (
                  <div
                    key={i}
                    className="flex flex-1 flex-col items-center justify-end gap-2"
                  >
                    <div
                      className="w-full rounded-md bg-gradient-to-t from-primary/40 to-primary transition-all"
                      style={{ height: `${h}%` }}
                    />
                    <span className="text-[10px] text-muted-foreground">
                      S{i + 1}
                    </span>
                  </div>
                ))}
              </div>
            </div>
            <div className="rounded-xl border border-border bg-muted/30 p-4 lg:col-span-2">
              <div className="mb-3 flex items-center gap-2 text-sm font-medium text-foreground">
                <Workflow className="h-4 w-4 text-primary" />
                Automações ativas
              </div>
              <ul className="space-y-2.5">
                {[
                  { t: "Conciliação Itaú concluída", ok: true },
                  { t: "47 notas fiscais emitidas", ok: true },
                  { t: "Relatório mensal enviado", ok: true },
                  { t: "DCTF gerada", ok: true },
                ].map((it, i) => (
                  <li
                    key={i}
                    className="flex items-center gap-2.5 rounded-lg border border-border/70 bg-background px-3 py-2"
                  >
                    <span className="grid h-5 w-5 place-items-center rounded-full bg-primary/15 text-primary">
                      <Check className="h-3 w-3" />
                    </span>
                    <span className="text-xs text-foreground">{it.t}</span>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function TrustStrip() {
  const items = [
    "Escritórios que confiam",
    "Banco do Brasil",
    "Itaú",
    "Bradesco",
    "Stone",
    "Sicoob",
    "Inter",
  ];
  const loop = [...items, ...items];
  return (
    <section className="border-y border-border/70 bg-muted/30">
      <div className="mx-auto flex max-w-7xl items-center gap-8 overflow-hidden px-5 py-6 sm:px-8">
        <div className="relative flex-1 overflow-hidden">
          <div className="marquee-track flex w-max items-center gap-10">
            {loop.map((t, i) => (
              <span
                key={i}
                className="whitespace-nowrap font-display text-sm font-medium text-muted-foreground/70"
              >
                {t}
              </span>
            ))}
          </div>
          <div className="pointer-events-none absolute inset-y-0 left-0 w-16 bg-gradient-to-r from-muted/30 to-transparent" />
          <div className="pointer-events-none absolute inset-y-0 right-0 w-16 bg-gradient-to-l from-muted/30 to-transparent" />
        </div>
      </div>
    </section>
  );
}

function Stats() {
  const stats = [
    { v: "93%", k: "das tarefas automatizadas", s: "conciência sem digitação" },
    { v: "41h", k: "economizadas por mês", s: "por escritório parceiro" },
    { v: "2.500+", k: "escritórios e empresas", s: "operando com a Numera" },
    { v: "99,9%", k: "de uptime", s: "infraestrutura disponível" },
  ];
  return (
    <section className="mx-auto max-w-7xl px-5 py-16 sm:px-8 sm:py-20">
      <div className="grid grid-cols-2 gap-4 sm:gap-6 lg:grid-cols-4">
        {stats.map((s) => (
          <div
            key={s.k}
            className="rounded-2xl border border-border bg-card p-6 text-center sm:text-left"
          >
            <p className="font-display text-4xl font-semibold tracking-tight text-foreground sm:text-5xl">
              {s.v}
            </p>
            <p className="mt-2 text-sm font-medium text-foreground">{s.k}</p>
            <p className="mt-0.5 text-xs text-muted-foreground">{s.s}</p>
          </div>
        ))}
      </div>
    </section>
  );
}

const FEATURES = [
  {
    icon: Landmark,
    title: "Conciliação bancária automática",
    desc: "Importação direta via Open Finance e OFX. A IA casa lançamentos, classifica por centro de custo e reconcilia em segundos.",
    span: "lg:col-span-2",
  },
  {
    icon: FileText,
    title: "Notas fiscais sem fricção",
    desc: "Emissão, recebimento e conferência de NF-e/NFS-e com leitura automática de XML.",
    span: "lg:col-span-1",
  },
  {
    icon: Receipt,
    title: "Fiscal automatizado",
    desc: "Apuração de impostos, DCTF, SPED e ECD gerados e validados no prazo.",
    span: "lg:col-span-1",
  },
  {
    icon: BellRing,
    title: "Alertas em tempo real",
    desc: "Monitora prazos, inconsistências e oportunidades e avisa antes do problema acontecer.",
    span: "lg:col-span-2",
  },
];

function Features() {
  return (
    <section id="recursos" className="mx-auto max-w-7xl px-5 py-20 sm:px-8 sm:py-28">
      <div className="max-w-2xl">
        <p className="text-sm font-semibold uppercase tracking-wider text-primary">
          Recursos
        </p>
        <h2 className="mt-3 text-balance text-3xl font-semibold tracking-tight text-foreground sm:text-4xl">
          Tudo o que sua contabilidade faz — automatizado
        </h2>
        <p className="mt-4 text-lg text-muted-foreground">
          Da conciliação ao fechamento fiscal, a Numera executa as rotinas
          repetitivas para que sua equipe foque no que gera valor.
        </p>
      </div>
      <div className="mt-12 grid gap-4 lg:grid-cols-3">
        {FEATURES.map((f) => {
          const Icon = f.icon;
          return (
            <div
              key={f.title}
              className={`group card-elevated rounded-3xl p-7 transition-all hover:-translate-y-0.5 hover:shadow-xl ${f.span}`}
            >
              <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-primary/10 text-primary ring-1 ring-inset ring-primary/15">
                <Icon className="h-6 w-6" />
              </div>
              <h3 className="mt-5 text-xl font-semibold text-foreground">
                {f.title}
              </h3>
              <p className="mt-2.5 text-sm leading-relaxed text-muted-foreground">
                {f.desc}
              </p>
            </div>
          );
        })}
      </div>
    </section>
  );
}

function Platform() {
  const rows = [
    { label: "Lançamentos conciliados", v: "12.480", pct: 96 },
    { label: "Notas processadas", v: "3.294", pct: 88 },
    { label: "Obrigações geradas", v: "210", pct: 74 },
    { label: "Relatórios enviados", v: "186", pct: 82 },
  ];
  return (
    <section
      id="plataforma"
      className="bg-surface text-surface-foreground"
    >
      <div className="mx-auto grid max-w-7xl items-center gap-12 px-5 py-20 sm:px-8 sm:py-28 lg:grid-cols-2">
        <div>
          <Badge className="border-white/15 bg-white/5 text-surface-foreground hover:bg-white/5">
            <Bot className="mr-1.5 h-3.5 w-3.5 text-gold" />
            Plataforma
          </Badge>
          <h2 className="mt-5 text-balance text-3xl font-semibold tracking-tight sm:text-4xl">
            Um painel que organiza toda a operação contábil
          </h2>
          <p className="mt-4 text-lg text-surface-foreground/70">
            Veja conciliações, impostos, relatórios e tarefas em um só lugar.
            Cada número é atualizado automaticamente pelas automações que rodam
            em segundo plano.
          </p>
          <ul className="mt-8 space-y-4">
            {[
              "Centros de custo e filiais consolidados em tempo real",
              "Auditoria total: cada lançamento rastreável até o documento",
              "Permissões por equipe, cliente e tipo de operação",
            ].map((t) => (
              <li key={t} className="flex items-start gap-3">
                <span className="mt-0.5 grid h-6 w-6 shrink-0 place-items-center rounded-full bg-primary/20 text-primary">
                  <Check className="h-3.5 w-3.5" />
                </span>
                <span className="text-surface-foreground/85">{t}</span>
              </li>
            ))}
          </ul>
          <Button asChild className="btn-primary-glow mt-9">
            <a href="#precos">
              Agendar demonstração
              <ArrowRight className="ml-2 h-4 w-4" />
            </a>
          </Button>
        </div>
        <div className="rounded-3xl border border-white/10 bg-white/[0.04] p-5 backdrop-blur">
          <div className="mb-4 flex items-center justify-between">
            <div className="flex items-center gap-2 text-sm font-medium">
              <LineChart className="h-4 w-4 text-gold" />
              Produtividade da automação
            </div>
            <span className="text-xs text-surface-foreground/50">Set/2026</span>
          </div>
          <div className="space-y-4">
            {rows.map((r) => (
              <div key={r.label}>
                <div className="mb-1.5 flex items-center justify-between text-sm">
                  <span className="text-surface-foreground/75">{r.label}</span>
                  <span className="font-semibold text-surface-foreground">
                    {r.v}
                  </span>
                </div>
                <div className="h-2 overflow-hidden rounded-full bg-white/10">
                  <div
                    className="h-full rounded-full bg-gradient-to-r from-primary to-gold"
                    style={{ width: `${r.pct}%` }}
                  />
                </div>
              </div>
            ))}
          </div>
          <div className="mt-5 grid grid-cols-3 gap-3 border-t border-white/10 pt-5">
            <div>
              <p className="font-display text-2xl font-semibold text-gold">99,8%</p>
              <p className="text-[11px] text-surface-foreground/60">
                acerto da IA
              </p>
            </div>
            <div>
              <p className="font-display text-2xl font-semibold text-surface-foreground">
                -64%
              </p>
              <p className="text-[11px] text-surface-foreground/60">
                retrabalho
              </p>
            </div>
            <div>
              <p className="font-display text-2xl font-semibold text-surface-foreground">
                24/7
              </p>
              <p className="text-[11px] text-surface-foreground/60">rodando</p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

function HowItWorks() {
  const steps = [
    {
      icon: Landmark,
      n: "01",
      title: "Conecte suas fontes",
      desc: "Vincule bancos, emissores de nota e ERPs em minutos. Importamos dados históricos e começamos a sincronizar.",
    },
    {
      icon: Bot,
      n: "02",
      title: "A IA organiza e concilia",
      desc: "Lançamentos classificados, impostos apurados e inconsistências resolvidas automaticamente, com revisão humana quando necessário.",
    },
    {
      icon: BarChart3,
      n: "03",
      title: "Receba relatórios prontos",
      desc: "Relatórios gerenciais, obrigações e demonstrativos ficam prontos para você aprovar e enviar ao cliente.",
    },
  ];
  return (
    <section id="como-funciona" className="mx-auto max-w-7xl px-5 py-20 sm:px-8 sm:py-28">
      <div className="mx-auto max-w-2xl text-center">
        <p className="text-sm font-semibold uppercase tracking-wider text-primary">
          Como funciona
        </p>
        <h2 className="mt-3 text-balance text-3xl font-semibold tracking-tight text-foreground sm:text-4xl">
          Três passos para uma contabilidade automática
        </h2>
      </div>
      <div className="mt-14 grid gap-6 md:grid-cols-3">
        {steps.map((s) => {
          const Icon = s.icon;
          return (
            <div
              key={s.n}
              className="relative rounded-3xl border border-border bg-card p-8"
            >
              <span className="absolute right-6 top-6 font-display text-4xl font-semibold text-primary/15">
                {s.n}
              </span>
              <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-primary/10 text-primary ring-1 ring-inset ring-primary/15">
                <Icon className="h-6 w-6" />
              </div>
              <h3 className="mt-5 text-xl font-semibold text-foreground">
                {s.title}
              </h3>
              <p className="mt-2.5 text-sm leading-relaxed text-muted-foreground">
                {s.desc}
              </p>
            </div>
          );
        })}
      </div>
    </section>
  );
}

const PLANS = [
  {
    name: "Starter",
    price: "R$ 149",
    period: "/mês",
    desc: "Para contadores e pequenas empresas começando a automatizar.",
    features: [
      "1 empresa",
      "Conciliação automática",
      "Emissão de notas",
      "Relatórios mensais",
      "Suporte por e-mail",
    ],
    cta: "Começar grátis",
    highlight: false,
  },
  {
    name: "Pro",
    price: "R$ 399",
    period: "/mês",
    desc: "Para escritórios que gerenciam vários clientes com escala.",
    features: [
      "Até 15 empresas",
      "Automação fiscal completa",
      "Integrações bancárias ilimitadas",
      "Relatórios e dashboards gerenciais",
      "Aprovações e fluxos por equipe",
      "Suporte prioritário",
    ],
    cta: "Testar 14 dias",
    highlight: true,
  },
  {
    name: "Enterprise",
    price: "Sob consulta",
    period: "",
    desc: "Para redes e contabilidades com alto volume e demandas customizadas.",
    features: [
      "Empresas ilimitadas",
      "API e integrações dedicadas",
      "SSO e auditoria avançada",
      "Onboarding e CSM dedicado",
      "SLA de 99,9%",
    ],
    cta: "Falar com vendas",
    highlight: false,
  },
];

function Pricing() {
  return (
    <section id="precos" className="relative overflow-hidden bg-muted/30">
      <div className="absolute inset-0 grid-lines opacity-40" aria-hidden />
      <div className="relative mx-auto max-w-7xl px-5 py-20 sm:px-8 sm:py-28">
        <div className="mx-auto max-w-2xl text-center">
          <p className="text-sm font-semibold uppercase tracking-wider text-primary">
            Preços
          </p>
          <h2 className="mt-3 text-balance text-3xl font-semibold tracking-tight text-foreground sm:text-4xl">
            Planos que pagam o próprio custo em tempo
          </h2>
          <p className="mt-4 text-lg text-muted-foreground">
            Comece grátis por 14 dias. Sem cartão de crédito.
          </p>
        </div>
        <div className="mt-14 grid items-stretch gap-6 lg:grid-cols-3">
          {PLANS.map((p) => (
            <div
              key={p.name}
              className={`relative flex flex-col rounded-3xl border p-8 ${
                p.highlight
                  ? "border-primary/40 bg-card shadow-[0_24px_60px_-24px_oklch(0.52_0.13_162/0.45)] ring-1 ring-primary/20"
                  : "border-border bg-card"
              }`}
            >
              {p.highlight && (
                <span className="absolute -top-3 left-8 inline-flex items-center gap-1.5 rounded-full bg-primary px-3 py-1 text-xs font-semibold text-primary-foreground">
                  <Sparkles className="h-3.5 w-3.5" />
                  Mais popular
                </span>
              )}
              <h3 className="text-lg font-semibold text-foreground">{p.name}</h3>
              <p className="mt-1.5 text-sm text-muted-foreground">{p.desc}</p>
              <div className="mt-6 flex items-baseline gap-1">
                <span className="font-display text-4xl font-semibold tracking-tight text-foreground">
                  {p.price}
                </span>
                <span className="text-sm text-muted-foreground">{p.period}</span>
              </div>
              <ul className="mt-6 flex-1 space-y-3">
                {p.features.map((f) => (
                  <li key={f} className="flex items-start gap-2.5 text-sm">
                    <Check className="mt-0.5 h-4 w-4 shrink-0 text-primary" />
                    <span className="text-foreground/90">{f}</span>
                  </li>
                ))}
              </ul>
              <Button
                asChild
                className={`mt-8 w-full ${
                  p.highlight ? "btn-primary-glow" : ""
                }`}
                variant={p.highlight ? "default" : "outline"}
              >
                <a href="#contato">{p.cta}</a>
              </Button>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function Testimonial() {
  return (
    <section className="mx-auto max-w-7xl px-5 py-20 sm:px-8 sm:py-28">
      <figure className="relative overflow-hidden rounded-3xl border border-border bg-card p-8 sm:p-12">
        <Quote className="absolute right-8 top-8 h-16 w-16 text-primary/10" />
        <div className="max-w-3xl">
          <div className="flex gap-1 text-gold">
            {Array.from({ length: 5 }).map((_, i) => (
              <span key={i}>★</span>
            ))}
          </div>
          <blockquote className="mt-6 text-balance text-2xl font-medium leading-snug text-foreground sm:text-3xl">
            “Reduzimos em 60% o tempo de fechamento mensal. A Numera concilia e
            classifica tudo sozinha — nossa equipe parou de digitar lançamentos
            e passou a assessorar os clientes.”
          </blockquote>
          <figcaption className="mt-7 flex items-center gap-4">
            <div className="grid h-12 w-12 place-items-center rounded-full bg-primary/10 font-display font-semibold text-primary">
              MR
            </div>
            <div>
              <p className="font-semibold text-foreground">Mariana Rocha</p>
              <p className="text-sm text-muted-foreground">
                Sócia · Rocha Contabilidade
              </p>
            </div>
          </figcaption>
        </div>
      </figure>
    </section>
  );
}

const FAQS = [
  {
    q: "A Numera substitui meu contador?",
    a: "Não. Ela automatiza as rotinas repetitivas para que o contador foque em análise, planejamento e atendimento. O time acompanha e aprova tudo o que a plataforma executa.",
  },
  {
    q: "Funciona com o meu banco e emissor de notas?",
    a: "Sim. Integramos via Open Finance com os principais bancos brasileiros e suportamos NF-e/NFS-e dos principais emissores. A importação de OFX e XML também está disponível.",
  },
  {
    q: "Os dados fiscais ficam seguros?",
    a: "Sim. Usamos criptografia em trânsito e repouso, controles de acesso por equipe e cliente, e auditoria completa de cada operação. Cumprimos os requisitos da LGPD.",
  },
  {
    q: "Preciso instalar algo?",
    a: "Não. A Numera é 100% na web. Você acessa de qualquer lugar e as automações rodam em segundo plano, 24/7.",
  },
  {
    q: "Posso migrar meus clientes existentes?",
    a: "Sim. Nossa equipe ajuda na importação do histórico e na configuração das integrações durante o onboarding, sem custo adicional nos planos Pro e Enterprise.",
  },
];

function Faq() {
  return (
    <section id="faq" className="mx-auto max-w-3xl px-5 py-20 sm:px-8 sm:py-28">
      <div className="text-center">
        <p className="text-sm font-semibold uppercase tracking-wider text-primary">
          FAQ
        </p>
        <h2 className="mt-3 text-balance text-3xl font-semibold tracking-tight text-foreground sm:text-4xl">
          Perguntas frequentes
        </h2>
      </div>
      <Accordion type="single" collapsible className="mt-10">
        {FAQS.map((f, i) => (
          <AccordionItem
            key={i}
            value={`item-${i}`}
            className="rounded-2xl border border-border bg-card px-5 mb-3 data-[state=open]:shadow-sm"
          >
            <AccordionTrigger className="text-left text-base font-medium hover:no-underline">
              {f.q}
            </AccordionTrigger>
            <AccordionContent className="text-muted-foreground">
              {f.a}
            </AccordionContent>
          </AccordionItem>
        ))}
      </Accordion>
    </section>
  );
}

function FinalCta() {
  return (
    <section id="contato" className="mx-auto max-w-7xl px-5 pb-20 sm:px-8 sm:pb-28">
      <div className="relative overflow-hidden rounded-[2rem] bg-surface px-6 py-16 text-center text-surface-foreground sm:px-16 sm:py-20">
        <div
          className="absolute inset-0 opacity-70"
          style={{
            background:
              "radial-gradient(50% 60% at 50% 0%, oklch(0.7 0.15 160 / 0.30), transparent 70%)",
          }}
          aria-hidden
        />
        <div className="relative mx-auto max-w-2xl">
          <Badge className="border-white/15 bg-white/5 text-surface-foreground hover:bg-white/5">
            <Sparkles className="mr-1.5 h-3.5 w-3.5 text-gold" />
            Comece hoje
          </Badge>
          <h2 className="mt-5 text-balance text-3xl font-semibold tracking-tight sm:text-4xl">
            Liberte sua contabilidade do trabalho manual
          </h2>
          <p className="mt-4 text-lg text-surface-foreground/70">
            Junte-se a mais de 2.500 escritórios que automatizaram suas rotinas
            com a Numera. 14 dias grátis, sem cartão.
          </p>
          <div className="mt-9 flex flex-col items-center justify-center gap-3 sm:flex-row">
            <Button asChild size="lg" className="btn-primary-glow w-full sm:w-auto">
              <a href="#precos">
                Começar grátis
                <ArrowRight className="ml-2 h-4 w-4" />
              </a>
            </Button>
            <Button
              asChild
              size="lg"
              variant="outline"
              className="w-full border-white/20 bg-transparent text-surface-foreground hover:bg-white/10 hover:text-surface-foreground sm:w-auto"
            >
              <a href="#contato">Falar com vendas</a>
            </Button>
          </div>
        </div>
      </div>
    </section>
  );
}

function Footer() {
  const cols = [
    { title: "Produto", links: ["Recursos", "Plataforma", "Preços", "Segurança", "Novidades"] },
    { title: "Empresa", links: ["Sobre", "Carreiras", "Blog", "Contato"] },
    { title: "Suporte", links: ["Central de ajuda", "Documentação", "Status", "API"] },
    { title: "Legal", links: ["Privacidade", "Termos", "LGPD", "Cookies"] },
  ];
  return (
    <footer className="border-t border-border bg-background">
      <div className="mx-auto max-w-7xl px-5 py-14 sm:px-8">
        <div className="grid gap-10 lg:grid-cols-6">
          <div className="lg:col-span-2">
            <Logo />
            <p className="mt-4 max-w-xs text-sm text-muted-foreground">
              Contabilidade inteligente e automação para escritórios e empresas
              que querem operar com escala.
            </p>
            <div className="mt-5 flex items-center gap-2 text-xs text-muted-foreground">
              <ShieldCheck className="h-4 w-4 text-primary" />
              Conformidade LGPD · ISO 27001
            </div>
          </div>
          {cols.map((c) => (
            <div key={c.title}>
              <h4 className="text-sm font-semibold text-foreground">{c.title}</h4>
              <ul className="mt-4 space-y-3">
                {c.links.map((l) => (
                  <li key={l}>
                    <a
                      href="#"
                      className="text-sm text-muted-foreground transition-colors hover:text-foreground"
                    >
                      {l}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
        <div className="mt-12 flex flex-col items-center justify-between gap-4 border-t border-border pt-6 text-xs text-muted-foreground sm:flex-row">
          <p>© {new Date().getFullYear()} Numera. Todos os direitos reservados.</p>
          <p>Feito no Brasil 🇧🇷</p>
        </div>
      </div>
    </footer>
  );
}

function Index() {
  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      <main>
        <Hero />
        <TrustStrip />
        <Stats />
        <Features />
        <Platform />
        <HowItWorks />
        <Testimonial />
        <Pricing />
        <Faq />
        <FinalCta />
      </main>
      <Footer />
    </div>
  );
}
