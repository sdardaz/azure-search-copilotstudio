// Generator for docs/diagrams/architecture.pptx — the architecture deck.
//
//   python docs/diagrams/logos_from_zips.py <dir-with-the-official-icon-zips>
//   npm install pptxgenjs && node docs/diagrams/architecture_pptx.js
//
// Edit this file rather than the .pptx: every box, connector and label is
// positioned here in inches on a 13.333 x 7.5 canvas.
//
// Product logos are read from ./logos/<slot>.png, which is gitignored because
// Microsoft's icon terms permit use but not redistribution. Any slot whose file
// is absent falls back to a dashed placeholder and is reported on stderr, so a
// run without the icons still produces a complete (if unbranded) deck.

const fs = require("fs");
const path = require("path");
const pptxgen = require("pptxgenjs");

const LOGO_DIR = path.join(__dirname, "logos");
const missingLogos = new Set();

function logoData(slot) {
  if (!slot) return null;
  const file = path.join(LOGO_DIR, slot + ".png");
  if (!fs.existsSync(file)) {
    missingLogos.add(slot);
    return null;
  }
  return "image/png;base64," + fs.readFileSync(file).toString("base64");
}

// ---------------------------------------------------------------- palette
const AZ = "0078D4"; // Azure blue
const NAVY = "243A5E"; // Microsoft deep navy
const GREY = "605E5C"; // neutral secondary
const MUTED = "8A8886";
const PURPLE = "8661C5"; // skillset execution
const GREEN = "107C41"; // Microsoft 365 / Power Platform
const PLACE_FILL = "F3F2F1";
const PLACE_LINE = "B3B3B3";
const F = "Segoe UI";

const pres = new pptxgen();
pres.layout = "LAYOUT_WIDE"; // 13.333 x 7.5
pres.author = "Soufyane Dardaz";
pres.title = "Pipeline d'ingestion documentaire pour Microsoft Copilot Studio";

// ---------------------------------------------------------------- helpers
const shadow = () => ({ type: "outer", color: "000000", blur: 4, offset: 1, angle: 90, opacity: 0.13 });

function logoBox(slide, x, y, size, label, slot) {
  const data = logoData(slot);
  if (data) {
    // Icons are square with their own internal padding, so they sit directly on
    // the card: no grey chip behind them.
    slide.addImage({ data, x, y, w: size, h: size });
    return;
  }
  slide.addShape(pres.ShapeType.roundRect, {
    x, y, w: size, h: size, rectRadius: 0.03,
    fill: { color: PLACE_FILL },
    line: { color: PLACE_LINE, width: 0.75, dashType: "dash" },
  });
  slide.addText(label || "LOGO", {
    x, y, w: size, h: size, fontFace: F, fontSize: 4.5, color: MUTED,
    align: "center", valign: "middle", margin: 0,
  });
}

// Service card with a logo placeholder, a title and a description.
function card(slide, o) {
  const big = o.h >= 0.85;
  slide.addShape(pres.ShapeType.roundRect, {
    x: o.x, y: o.y, w: o.w, h: o.h, rectRadius: 0.04,
    fill: { color: "FFFFFF" },
    line: { color: o.accent || AZ, width: 1 },
    shadow: shadow(),
  });
  const ls = o.logo || 0.26;
  logoBox(slide, o.x + 0.075, o.y + 0.075, ls, null, o.icon);
  slide.addText(o.title, {
    x: o.x + 0.075 + ls + 0.07, y: o.y + 0.045,
    w: o.w - (0.075 + ls + 0.07) - 0.07,
    h: ls + (o.th === undefined ? 0.06 : o.th),
    fontFace: F, fontSize: o.ts || (big ? 8.5 : 7.5), bold: true,
    color: NAVY, align: "left", valign: "middle", margin: 0, lineSpacingMultiple: 0.85,
  });
  if (o.desc) {
    const dy = o.y + ls + (o.dg === undefined ? 0.15 : o.dg);
    slide.addText(o.desc, {
      x: o.x + 0.085, y: dy, w: o.w - 0.17, h: o.y + o.h - dy - 0.05,
      fontFace: F, fontSize: o.ds || 6.5, color: GREY, align: "left", valign: "top",
      margin: 0, lineSpacingMultiple: 0.92,
    });
  }
  if (o.badge) {
    slide.addShape(pres.ShapeType.ellipse, {
      x: o.x - 0.12, y: o.y - 0.12, w: 0.23, h: 0.23,
      fill: { color: AZ }, line: { color: "FFFFFF", width: 1.25 },
    });
    slide.addText(String(o.badge), {
      x: o.x - 0.12, y: o.y - 0.12, w: 0.23, h: 0.23,
      fontFace: F, fontSize: 7, bold: true, color: "FFFFFF",
      align: "center", valign: "middle", margin: 0,
    });
  }
}

// Dashed scope boundary (Azure subscription, Microsoft 365, Power Platform...)
function boundary(slide, o) {
  if (!o.labelOnly) {
    slide.addShape(pres.ShapeType.roundRect, {
      x: o.x, y: o.y, w: o.w, h: o.h, rectRadius: 0.02,
      fill: { color: o.fill },
      line: { color: o.color, width: 1.25, dashType: "dash" },
    });
  }
  if (o.rectOnly) return;
  if (o.inline) {
    slide.addText(
      [
        { text: o.label, options: { bold: true, color: o.color, fontSize: o.lsz || 7.5 } },
        { text: "   ·   " + o.sub, options: { italic: true, color: GREY, fontSize: 6.5 } },
      ],
      {
        x: o.x + 0.08, y: o.y + 0.035, w: o.subw || (o.w - 0.16), h: 0.22,
        fontFace: F, align: "left", valign: "middle", margin: 0,
        fill: { color: o.fill },
      }
    );
    return;
  }
  slide.addText(o.label, {
    x: o.x + 0.10, y: o.y + 0.035, w: o.w - 0.20, h: 0.20,
    fontFace: F, fontSize: o.lsz || 7.5, bold: true, color: o.color,
    align: "left", valign: "middle", margin: 0, charSpacing: 0.6,
  });
  if (o.sub) {
    slide.addText(o.sub, {
      x: o.x + 0.10, y: o.y + 0.22, w: o.subw || (o.w - 0.20), h: 0.17,
      fontFace: F, fontSize: 6.5, italic: true, color: GREY,
      align: "left", valign: "middle", margin: 0,
    });
  }
}

// Straight connector. dir: "right" | "down" | "up" | "left"
function arrow(slide, x, y, len, dir, o) {
  o = o || {};
  const line = {
    color: o.color || AZ,
    width: o.width || 1.25,
    endArrowType: o.noHead ? "none" : "triangle",
  };
  if (o.dash) line.dashType = "dash";
  if (dir === "right") slide.addShape(pres.ShapeType.line, { x, y, w: len, h: 0, line });
  else if (dir === "down") slide.addShape(pres.ShapeType.line, { x, y, w: 0, h: len, line });
  else if (dir === "up") {
    // draw downward but put the head at the start so it points up
    const l = { ...line, endArrowType: "none", beginArrowType: o.noHead ? "none" : "triangle" };
    slide.addShape(pres.ShapeType.line, { x, y: y - len, w: 0, h: len, line: l });
  } else if (dir === "left") {
    const l = { ...line, endArrowType: "none", beginArrowType: o.noHead ? "none" : "triangle" };
    slide.addShape(pres.ShapeType.line, { x: x - len, y, w: len, h: 0, line: l });
  }
}

function edgeLabel(slide, x, y, w, txt, align) {
  slide.addText(txt, {
    x, y, w, h: 0.20, fontFace: F, fontSize: 6, color: GREY,
    align: align || "center", valign: "middle", margin: 0,
  });
}

function slideHeader(slide, title, sub) {
  slide.background = { color: "FFFFFF" };
  slide.addText(title, {
    x: 0.35, y: 0.20, w: 10.0, h: 0.34, fontFace: F, fontSize: 19, bold: true,
    color: NAVY, align: "left", valign: "middle", margin: 0,
  });
  if (sub) {
    slide.addText(sub, {
      x: 0.35, y: 0.58, w: 11.6, h: 0.22, fontFace: F, fontSize: 9,
      color: GREY, align: "left", valign: "middle", margin: 0,
    });
  }
  slide.addText("Soufyane Dardaz  ·  v2.0", {
    x: 10.45, y: 0.26, w: 1.80, h: 0.22, fontFace: F, fontSize: 7.5,
    color: MUTED, align: "right", valign: "middle", margin: 0,
  });
  logoBox(slide, 12.35, 0.24, 0.60, "LOGO\nORG");
}

// ================================================================ SLIDE 1
const s1 = pres.addSlide();
slideHeader(
  s1,
  "Pipeline d'ingestion documentaire pour Microsoft Copilot Studio",
  "Architecture technique — indexation dans Azure AI Search, consommée par le connecteur natif « Azure AI Search » de Microsoft Copilot Studio"
);

// -- scopes
boundary(s1, {
  x: 0.35, y: 1.05, w: 1.95, h: 2.62, fill: "FAFAFA", color: GREY,
  label: "SOURCES",
});
boundary(s1, {
  x: 2.45, y: 1.05, w: 8.42, h: 5.35, fill: "F3F9FD", color: AZ,
  label: "MICROSOFT AZURE  —  abonnement / groupe de ressources",
  sub: "identités managées · Azure RBAC · authentification locale désactivée",
});
boundary(s1, {
  x: 11.02, y: 1.35, w: 1.96, h: 1.42, fill: "F1F8F4", color: GREEN,
  label: "POWER PLATFORM", lsz: 6.5,
});

// -- sources
card(s1, {
  x: 0.46, y: 1.70, w: 1.73, h: 0.88, accent: GREY, badge: 1,
  icon: "sharepoint",
  title: "SharePoint dans Microsoft 365",
  desc: "Bibliothèque de documents,\nsource de vérité métier",
});
card(s1, {
  x: 0.46, y: 2.72, w: 1.73, h: 0.80, accent: GREY,
  icon: "local-files",
  title: "Fichiers locaux · ./data",
  desc: "Ingestion ponctuelle (CLI)",
});

// -- main row inside Azure
const RY = 1.70, RH = 0.88, RC = RY + RH / 2; // 2.14
card(s1, {
  x: 2.57, y: RY, w: 1.775, h: RH, badge: 2,
  icon: "logic-apps",
  title: "Azure Logic Apps",
  desc: "Consommation · déclencheur\nrécurrent (15 min par défaut)",
});
card(s1, {
  x: 4.705, y: RY, w: 1.775, h: RH, badge: 3,
  icon: "blob-storage",
  title: "Azure Blob Storage",
  desc: "Conteneurs content + images\nzone d'atterrissage · soft-delete",
});
card(s1, {
  x: 6.84, y: RY, w: 1.775, h: RH, badge: 4,
  icon: "ai-search",
  title: "Azure AI Search — Indexeur",
  desc: "Planification, suivi des\nchangements, relances, lots",
});
card(s1, {
  x: 8.975, y: RY, w: 1.775, h: RH, badge: 9,
  icon: "ai-search",
  title: "Azure AI Search — Index",
  desc: "1 document d'index = 1 chunk\nhybride + ranker sémantique",
});

// -- Power Platform + user
card(s1, {
  x: 11.13, y: RY, w: 1.74, h: RH, accent: GREEN, badge: 10,
  icon: "copilot-studio",
  title: "Microsoft Copilot Studio",
  desc: "Connaissances → connecteur\nnatif « Azure AI Search »",
});
card(s1, {
  x: 11.13, y: 3.10, w: 1.74, h: 0.78, accent: GREY, badge: 11,
  icon: "user",
  title: "Utilisateur métier",
  desc: "Microsoft Teams · web · M365",
});

// -- main flow arrows
arrow(s1, 2.21, RC, 0.34, "right");
arrow(s1, 4.36, RC, 0.34, "right");
arrow(s1, 6.50, RC, 0.34, "right");
arrow(s1, 8.63, RC, 0.34, "right");
arrow(s1, 10.77, RC, 0.34, "right");
arrow(s1, 12.00, 2.58, 0.52, "down");


// -- CLI path: ./data -> Blob (dashed)
arrow(s1, 2.19, 2.78, 3.40, "right", { dash: true, noHead: true, width: 1 });
arrow(s1, 5.5925, 2.78, 0.20, "up", { dash: true, width: 1 });
edgeLabel(s1, 2.60, 2.62, 1.30, "prepdocs.py (CLI)", "left");

// -- skillset band
boundary(s1, {
  x: 2.57, y: 3.02, w: 6.045, h: 1.48, fill: "FFFFFF", color: AZ, inline: true,
  label: "ENRICHISSEMENT  —  skillset Azure AI Search",
  sub: "compétences personnalisées sur Azure Functions",
});
const SW = 1.325, SY = 3.42, SH = 0.96;
const sx = [2.69, 4.185, 5.68, 7.175];
card(s1, { x: sx[0], y: SY, w: SW, h: SH, badge: 5, logo: 0.24, ts: 7, ds: 5.8, th: 0.16, dg: 0.24,
  icon: "functions",
  title: "Document\nExtractor",
  desc: "Télécharge le blob, extrait texte,\ntableaux et figures ; lit les ACL" });
card(s1, { x: sx[1], y: SY, w: SW, h: SH, badge: 6, logo: 0.24, ts: 7, ds: 5.8, th: 0.16, dg: 0.24,
  icon: "functions",
  title: "Figure\nProcessor",
  desc: "Recadre la figure, la décrit,\nvectorise l'image" });
card(s1, { x: sx[2], y: SY, w: SW, h: SH, badge: 7, logo: 0.24, ts: 7, ds: 5.8, th: 0.16, dg: 0.24,
  icon: "ai-search",
  title: "Shaper\n(intégré)",
  desc: "Consolide pages et figures\nen un objet unique" });
card(s1, { x: sx[3], y: SY, w: SW, h: SH, badge: 8, logo: 0.24, ts: 7, ds: 5.8, th: 0.16, dg: 0.24,
  icon: "functions",
  title: "Text\nProcessor",
  desc: "Fusionne, découpe en chunks,\ncalcule les embeddings" });

arrow(s1, 4.025, SY + SH / 2, 0.15, "right", { color: PURPLE });
arrow(s1, 5.52, SY + SH / 2, 0.15, "right", { color: PURPLE });
arrow(s1, 7.015, SY + SH / 2, 0.15, "right", { color: PURPLE });

// indexer -> skillset, skillset -> indexer
arrow(s1, 7.90, 2.58, 0.44, "down", { color: PURPLE });
arrow(s1, 8.35, SY, SY - 2.58, "up", { color: PURPLE });

// -- managed AI services band
const svcBand = {
  x: 2.57, y: 4.72, w: 6.045, h: 1.52, fill: "FFFFFF", color: AZ, inline: true,
  label: "SERVICES IA MANAGÉS",
  sub: "appelés par les compétences ci-dessus, jamais exposés publiquement",
};
boundary(s1, { ...svcBand, rectOnly: true });
const VY = 5.10, VH = 1.00;
card(s1, { x: sx[0], y: VY, w: SW, h: VH, logo: 0.24, ts: 7, ds: 5.8, th: 0.16, dg: 0.24,
  icon: "document-intelligence",
  title: "Azure AI Document\nIntelligence",
  desc: "Modèle layout : texte, tableaux\n(→ HTML), figures + coordonnées" });
card(s1, { x: sx[1], y: VY, w: SW, h: VH, logo: 0.24, ts: 7, ds: 5.8, th: 0.16, dg: 0.24,
  icon: "ai-vision",
  title: "Azure AI Vision",
  desc: "Embeddings d'images\n(multimodal, option)" });
card(s1, { x: sx[2], y: VY, w: SW, h: VH, logo: 0.24, ts: 7, ds: 5.8, th: 0.16, dg: 0.24,
  icon: "content-understanding",
  title: "Azure AI Content\nUnderstanding",
  desc: "Description de médias\n(alternative, option)" });
card(s1, { x: sx[3], y: VY, w: SW, h: VH, logo: 0.24, ts: 7, ds: 5.8, th: 0.16, dg: 0.24,
  icon: "foundry",
  title: "Microsoft Foundry",
  desc: "Azure OpenAI : text-embedding-3-large (3072 dim.) et modèle vision pour les figures" });

const dl = { dash: true, color: GREY, width: 1 };
const SB = SY + SH; // 4.38
arrow(s1, sx[0] + SW / 2, SB, 0.68, "down", dl);
arrow(s1, sx[1] + SW / 2, SB, 0.68, "down", dl);
arrow(s1, sx[3] + SW / 2, SB, 0.68, "down", dl);
// figure processor -> content understanding (elbow)
arrow(s1, 5.20, SB, 0.22, "down", { ...dl, noHead: true });
arrow(s1, 5.20, SB + 0.22, 1.1425, "right", { ...dl, noHead: true });
arrow(s1, sx[2] + SW / 2, SB + 0.22, 0.46, "down", dl);
boundary(s1, { ...svcBand, labelOnly: true });

// -- index schema + monitor (right column inside Azure)
slide1Schema();
function slide1Schema() {
  s1.addShape(pres.ShapeType.roundRect, {
    x: 8.975, y: 2.72, w: 1.775, h: 1.78, rectRadius: 0.04,
    fill: { color: "FFFFFF" }, line: { color: AZ, width: 1 },
  });
  s1.addText("Schéma de l'index", {
    x: 9.07, y: 2.79, w: 1.59, h: 0.18, fontFace: F, fontSize: 7, bold: true,
    color: NAVY, align: "left", valign: "middle", margin: 0,
  });
  s1.addText(
    "id (clé) · parent_id\n" +
    "content (searchable)\n" +
    "sourcepage · sourcefile\n" +
    "storageUrl → citations\n" +
    "embedding3 : HNSW / cosinus\n" +
    "category (filtre)\n" +
    "images[] : embedding, url,\ndescription, bbox\n" +
    "oids / groups → droits (option)\n" +
    "config. sémantique default",
    {
      x: 9.07, y: 2.99, w: 1.59, h: 1.45, fontFace: F, fontSize: 6, color: GREY,
      align: "left", valign: "top", margin: 0, lineSpacingMultiple: 0.95,
    }
  );
  card(s1, {
    x: 8.975, y: 4.72, w: 1.775, h: 1.04, logo: 0.24, ts: 7, ds: 5.8, th: 0.16, dg: 0.24,
    icon: "monitor",
  title: "Azure Monitor",
    desc: "Application Insights + Log Analytics\ndiagnostics indexeur, Functions,\nLogic App",
  });
  s1.addText("Reçoit la télémétrie de l'ensemble des composants Azure ci-contre.", {
    x: 8.975, y: 5.84, w: 1.775, h: 0.30, fontFace: F, fontSize: 6, italic: true,
    color: MUTED, align: "left", valign: "top", margin: 0, lineSpacingMultiple: 0.95,
  });
}

// -- legend
const LY = 6.66;
function legendItem(x, color, txt, dashed) {
  s1.addShape(pres.ShapeType.roundRect, {
    x, y: LY + 0.03, w: 0.20, h: 0.14, rectRadius: 0.03,
    fill: { color: dashed ? PLACE_FILL : "FFFFFF" },
    line: { color, width: 1, dashType: dashed ? "dash" : "solid" },
  });
  s1.addText(txt, {
    x: x + 0.27, y: LY, w: 2.65, h: 0.20, fontFace: F, fontSize: 7, color: NAVY,
    align: "left", valign: "middle", margin: 0,
  });
}
s1.addText("Légende", {
  x: 0.35, y: 6.44, w: 2.0, h: 0.20, fontFace: F, fontSize: 8, bold: true,
  color: NAVY, align: "left", valign: "middle", margin: 0,
});
legendItem(0.35, AZ, "Service Azure managé");
legendItem(2.05, GREEN, "Microsoft 365 / Power Platform");
legendItem(4.35, GREY, "Acteur ou source hors Azure");
legendItem(6.45, PLACE_LINE, "Emplacement réservé à votre logo (en-tête)", true);
s1.addText(
  "Trait plein bleu = flux de données principal   ·   trait violet = exécution du skillset par l'indexeur   ·   trait pointillé = appel de service ou chemin alternatif   ·   les pastilles 1 à 11 renvoient au détail de l'étape (slide suivante).",
  {
    x: 0.35, y: 6.98, w: 12.6, h: 0.22, fontFace: F, fontSize: 7, italic: true,
    color: GREY, align: "left", valign: "middle", margin: 0,
  }
);
s1.addNotes(
  "Schéma d'architecture technique du pipeline d'ingestion. Le flux principal va de gauche à droite : " +
  "SharePoint → Logic Apps → Blob Storage → indexeur Azure AI Search → index → Copilot Studio → utilisateur. " +
  "Le skillset (compétences sur Azure Functions) est exécuté par l'indexeur et s'appuie sur les services IA managés. " +
  "Les cadres pointillés gris sont les emplacements réservés aux logos officiels des produits."
);

// ================================================================ SLIDE 2
const s2 = pres.addSlide();
slideHeader(
  s2,
  "Flux de données, étape par étape",
  "Justification de chaque choix d'architecture. Chaque numéro correspond à une pastille du schéma précédent."
);

const steps = [
  [1, "SharePoint dans Microsoft 365 — source", "Les documents restent gérés là où le métier les gère déjà : droits, cycle de vie et versioning ne sont pas dupliqués. Aucune migration de contenu n'est nécessaire."],
  [2, "Azure Logic Apps — synchronisation incrémentale", "Déclencheur récurrent + requête delta Microsoft Graph : seuls les fichiers créés ou modifiés sont traités. Authentification par identité managée (permission Graph Sites.Selected), sans connecteur OAuth à réautoriser."],
  [3, "Azure Blob Storage — zone d'atterrissage", "Point d'entrée unique quelle que soit l'origine (SharePoint, CLI, dépôt manuel). Compte Azure Data Lake Storage Gen2 lorsque le filtrage par droits est activé. Le soft-delete natif sert de politique de détection de suppression."],
  [4, "Indexeur Azure AI Search — orchestrateur managé", "Le service Microsoft porte la planification, le suivi des changements, les relances et le traitement par lots. Aucun orchestrateur maison à héberger, patcher ni superviser."],
  [5, "Compétence « Document Extractor »", "Un seul composant connaît tous les formats : PDF, DOCX, PPTX, XLSX, PNG / JPG, HTML, JSON, CSV, TXT / MD. Les tableaux sont convertis en HTML pour préserver leur structure ; les figures sont localisées par coordonnées."],
  [6, "Compétence « Figure Processor »", "Graphiques, schémas et photos deviennent du texte recherchable (description générée par un modèle vision) et, en option, des vecteurs d'image. Sans cette étape, tout le contenu visuel serait invisible pour la recherche."],
  [7, "Compétence « Shaper » (intégrée Microsoft)", "Compétence native, sans code : consolide pages, figures et métadonnées en un objet unique. Réduit d'autant la surface de code personnalisé à maintenir."],
  [8, "Compétence « Text Processor »", "Découpe en chunks respectant les frontières de phrases, puis calcule les embeddings (text-embedding-3-large, 3072 dimensions). Le découpage conditionne directement la pertinence ; les vecteurs sont calculés une seule fois, à l'ingestion."],
  [9, "Index Azure AI Search — projection par chunk", "1 document d'index = 1 chunk (index projection, documents parents non indexés) : réponses précises et citations au niveau du passage plutôt que du fichier entier. Recherche hybride et ranker sémantique activables."],
  [10, "Microsoft Copilot Studio — connecteur natif", "Ajout via Connaissances → Azure AI Search, avec authentification Microsoft Entra ID intégrée. Copilot Studio porte l'orchestration, la réponse et les citations : aucun backend de conversation à développer, héberger ni sécuriser."],
  [11, "Utilisateur métier", "Pose sa question dans Microsoft Teams, sur le web ou dans Microsoft 365, et reçoit une réponse ancrée dans les documents de l'organisation, avec les liens de citation (storageUrl / metadata_storage_path)."],
];

const COLW = 6.15, ROWH = 0.90, TOPY = 1.05;
steps.forEach((st, i) => {
  const col = i % 2, row = Math.floor(i / 2);
  const x = 0.35 + col * (COLW + 0.53);
  const y = TOPY + row * (ROWH + 0.08);
  s2.addShape(pres.ShapeType.ellipse, {
    x, y: y + 0.06, w: 0.28, h: 0.28,
    fill: { color: AZ }, line: { color: AZ, width: 0 },
  });
  s2.addText(String(st[0]), {
    x, y: y + 0.06, w: 0.28, h: 0.28, fontFace: F, fontSize: 9, bold: true,
    color: "FFFFFF", align: "center", valign: "middle", margin: 0,
  });
  s2.addText(st[1], {
    x: x + 0.38, y: y + 0.01, w: COLW - 0.38, h: 0.22, fontFace: F, fontSize: 10,
    bold: true, color: NAVY, align: "left", valign: "middle", margin: 0,
  });
  s2.addText(st[2], {
    x: x + 0.38, y: y + 0.25, w: COLW - 0.38, h: 0.64, fontFace: F, fontSize: 8,
    color: GREY, align: "left", valign: "top", margin: 0, lineSpacingMultiple: 0.97,
  });
});

// alternative path callout, bottom-right (slot 12 of the grid)
const altX = 0.35 + (COLW + 0.53), altY = TOPY + 5 * (ROWH + 0.08);
s2.addShape(pres.ShapeType.roundRect, {
  x: altX - 0.06, y: altY, w: COLW + 0.12, h: ROWH, rectRadius: 0.04,
  fill: { color: "F5F5F5" }, line: { color: PLACE_LINE, width: 0.75, dashType: "dash" },
});
s2.addText("Chemin alternatif : ingestion locale (CLI)", {
  x: altX + 0.32, y: altY + 0.05, w: COLW - 0.38, h: 0.22, fontFace: F, fontSize: 10,
  bold: true, color: NAVY, align: "left", valign: "middle", margin: 0,
});
s2.addText(
  "prepdocs.py exécute la même bibliothèque de traitement (prepdocslib) depuis un poste ou un agent CI et écrit directement dans l'index. Utile pour une maquette ou un corpus figé, sans Functions ni Logic App (USE_CLOUD_INGESTION=false).",
  {
    x: altX + 0.32, y: altY + 0.29, w: COLW - 0.38, h: 0.58, fontFace: F, fontSize: 8,
    color: GREY, align: "left", valign: "top", margin: 0, lineSpacingMultiple: 0.97,
  }
);
s2.addNotes("Détail des 11 étapes numérotées du schéma d'architecture, avec la justification de chaque choix technique.");

// ================================================================ SLIDE 3
const s3 = pres.addSlide();
slideHeader(
  s3,
  "Robustesse, sécurité et exploitation",
  "Ce que l'architecture garantit en fonctionnement nominal et en cas d'incident."
);

function panel(slide, o) {
  slide.addShape(pres.ShapeType.roundRect, {
    x: o.x, y: o.y, w: o.w, h: o.h, rectRadius: 0.03,
    fill: { color: "FFFFFF" }, line: { color: o.color || AZ, width: 1 },
    shadow: shadow(),
  });
  logoBox(slide, o.x + 0.22, o.y + 0.24, 0.34, null, o.icon);
  slide.addText(o.title, {
    x: o.x + 0.68, y: o.y + 0.22, w: o.w - 0.90, h: 0.38, fontFace: F, fontSize: 13,
    bold: true, color: NAVY, align: "left", valign: "middle", margin: 0,
  });
  slide.addText(
    o.items.map((t, i) => ({
      text: t,
      options: { bullet: true, breakLine: i !== o.items.length - 1, paraSpaceAfter: 6 },
    })),
    {
      x: o.x + 0.26, y: o.y + 0.72, w: o.w - 0.52, h: o.h - 0.92, fontFace: F,
      fontSize: 9, color: GREY, align: "left", valign: "top", margin: 0,
      lineSpacingMultiple: 1.0,
    }
  );
}

const PW = 4.06, PX = [0.35, 4.63, 8.91];
panel(s3, {
  x: PX[0], y: 1.12, w: PW, h: 2.62, color: AZ, icon: "entra-id", title: "Identité & sécurité",
  items: [
    "Identités managées de bout en bout : Search → Storage / Foundry / Vision ; Functions → Storage / Search / Foundry / Document Intelligence ; Logic App → Graph / Storage / Search.",
    "Aucune clé stockée : disableLocalAuth sur Azure AI Search et Document Intelligence, allowSharedKeyAccess = false sur le compte de stockage.",
    "Les trois endpoints de compétences sont protégés par Microsoft Entra ID (authentification requise, sinon HTTP 401).",
  ],
});
panel(s3, {
  x: PX[1], y: 1.12, w: PW, h: 2.62, color: AZ, icon: "virtual-network", title: "Réseau",
  items: [
    "Private Endpoints optionnels : Blob Storage, Azure AI Search, comptes Cognitive Services / Foundry.",
    "Zones Azure Private DNS associées ; publicNetworkAccess peut être positionné à Disabled.",
    "Accès d'exploitation par passerelle VPN point-à-site et résolveur DNS privé (option).",
  ],
});
panel(s3, {
  x: PX[2], y: 1.12, w: PW, h: 2.62, color: AZ, icon: "monitor", title: "Observabilité & coûts",
  items: [
    "Application Insights + Log Analytics : Azure Functions, Logic App, diagnostics Azure AI Search.",
    "Historique d'exécution de l'indexeur et de la Logic App consultable dans le portail Azure.",
    "Coût récurrent principal : Azure AI Search, facturé à l'heure même index vide — dimensionner le SKU en premier.",
  ],
});

// robustness callout
s3.addShape(pres.ShapeType.roundRect, {
  x: 0.35, y: 4.00, w: 12.63, h: 1.42, rectRadius: 0.03,
  fill: { color: "FFF9E6" }, line: { color: "8A6100", width: 1 },
});
s3.addText("Robustesse de la synchronisation SharePoint (Azure Logic Apps)", {
  x: 0.60, y: 4.14, w: 12.1, h: 0.26, fontFace: F, fontSize: 12, bold: true,
  color: "4A3B00", align: "left", valign: "middle", margin: 0,
});
s3.addText(
  [
    { text: "deltaLink persisté dans la table Azure sharepointsyncstate → synchronisation incrémentale, reprenable et idempotente : un run interrompu reprend là où il s'est arrêté.", options: { bullet: true, breakLine: true, paraSpaceAfter: 4 } },
    { text: "L'échec d'un fichier isolé est capté dans un scope dédié, journalisé dans la table sharepointingestionerrors (et notifié par webhook si configuré) — le run continue sur les fichiers suivants.", options: { bullet: true, breakLine: true, paraSpaceAfter: 4 } },
    { text: "Une suppression dans SharePoint entraîne la suppression du blob, puis le retrait automatique du document de l'index via la politique de détection de suppression par soft-delete.", options: { bullet: true, breakLine: false } },
  ],
  {
    x: 0.60, y: 4.46, w: 12.1, h: 0.86, fontFace: F, fontSize: 9, color: "4A3B00",
    align: "left", valign: "top", margin: 0,
  }
);

// deployment note
s3.addShape(pres.ShapeType.roundRect, {
  x: 0.35, y: 5.62, w: 12.63, h: 1.10, rectRadius: 0.03,
  fill: { color: "F3F9FD" }, line: { color: AZ, width: 1 },
});
s3.addText("Déploiement", {
  x: 0.60, y: 5.74, w: 12.1, h: 0.24, fontFace: F, fontSize: 12, bold: true,
  color: NAVY, align: "left", valign: "middle", margin: 0,
});
s3.addText(
  [
    { text: "L'ensemble de l'architecture est décrit en Bicep et déployé par une seule commande azd up : Azure AI Search, Blob Storage, Microsoft Foundry, Document Intelligence, les trois Azure Functions et la Logic App.", options: { bullet: true, breakLine: true, paraSpaceAfter: 4 } },
    { text: "La Logic App est provisionnée à chaque déploiement, mais livrée à l'état Disabled tant que SHAREPOINT_HOSTNAME et SHAREPOINT_SITE_PATH ne sont pas renseignés — elle n'interroge donc jamais une URL Microsoft Graph invalide. Reste un consentement Graph Sites.Selected à accorder une fois par un administrateur.", options: { bullet: true, breakLine: false } },
  ],
  {
    x: 0.60, y: 6.02, w: 12.1, h: 0.60, fontFace: F, fontSize: 9, color: GREY,
    align: "left", valign: "top", margin: 0,
  }
);
s3.addNotes("Vue transverse : sécurité, réseau, observabilité, robustesse de la synchronisation et modalités de déploiement.");

pres.writeFile({ fileName: "architecture.pptx" }).then((f) => {
  console.log("written:", f);
  if (missingLogos.size) {
    console.error(
      "placeholders left for missing logos (run logos_from_zips.py): " +
        [...missingLogos].sort().join(", ")
    );
  }
});
