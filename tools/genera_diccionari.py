#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Verifica les paraules de tools/paraules/*.txt segons l'ortografia catalana
i genera LaTonicaEnCadena/Data/DiccionariLocal.swift.

Regles:
  1. Amb accent grafic (a e i o u + accent, o diaeresi): la silaba accentuada
     es la tonica. Posicio comptant des del final:
       1=aguda, 2=plana, 3=esdruixola, >=4=sobresdruixola.
  2. Sense accent: acaba en a/e/o -> plana; acaba en consonant (no -s/-d)
     -> aguda. Acaba en -i/-u/-y/-s/-d -> ambigua -> descartada.
  3. Descarts de seguretat: apostrofs, guionets, xifres.

Sillabacio (heuristica catalana):
  - diftong: strong+weak (au, eu, ai, oi, ei) i weak+weak (iu, ui) = 1 silaba
  - hiat: weak+strong (ia, io, ua, ue...) = 2 silabes
  - "u" darrere de "q" o de "g" (abans de e/i) no es compta com a vocal
  - la "y" es comporta com a vocal feble
"""

import os
import sys
import unicodedata

ARREL = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DADES = os.path.join(ARREL, "tools", "paraules")
SORTIDA = os.path.join(ARREL, "LaTonicaEnCadena", "Data", "DiccionariLocal.swift")

FORTESSA = set("aeoàèéòó")          # vocals fortes (con o sense accent)
FEVES = set("iuïúíü")               # vocals febles (con o sense accent)
TOTES = FORTESSA | FEVES | set("y")
ACENT = set("àèéíòóúïü")
VOCAL_FINAL_PLANA = set("ao")        # a/e/o sense accent -> plana
VOCAL_TANCADA = set("iuy")

CATEGORIES = ["agudes", "planes", "esdruixoles", "sobresdruixoles"]
NOM_TIPUS = {
    "agudes": ".aguda",
    "planes": ".plana",
    "esdruixoles": ".esdruixola",
    "sobresdruixoles": ".sobresdruixola",
}


def es_vocal(c):
    return c in TOTES


def vocal_a_acento(p):
    """Retorna (nombre_de_grups, grup_de_la_vocal_acentuada) o (n, None).
    Tenint en compte diftongs/hiats i qu/gu."""
    grups = []          # llista de grups; cada grup es llista de caracters
    i, L = 0, len(p)
    while i < L:
        c = p[i]
        if not es_vocal(c):
            i += 1
            continue
        # la "u" darrere de q o g (qu-, gu-) no compta, excepte si porta dièresi
        if c == "u" and c not in ACENT and i > 0 and p[i - 1] in "qg":
            seg = p[i + 1] if i + 1 < L else ""
            if seg in "ei":
                i += 1
                continue
        # formar grup
        grup = [c]
        j = i + 1
        while j < L and es_vocal(p[j]):
            ant = grup[-1]
            cur = p[j]
            amb_dues_fortes = ant in FORTESSA and cur in FORTESSA
            ant_accentuada = ant in ACENT
            cur_accentuada = cur in ACENT
            if ant_accentuada or cur_accentuada:
                # si la forta porta accent, trenquem (hiat) quan la primera es feble
                if ant in FEVES and cur in FORTESSA and not ant_accentuada:
                    break
                else:
                    grup.append(cur)
                    j += 1
                    break  # despres de l'accent, següent vocal = nou grup
            if amb_dues_fortes:
                break                      # hiat de fortes (a-e, a-o...)
            if ant in FEVES and cur in FORTESSA:
                break                      # hiat feble+forta (ia, ua...)
            # strong+weak (au, oi...) o weak+weak (iu) -> diftong
            grup.append(cur)
            j += 1
        grups.append("".join(grup))
        i = j
    return grups


def posicio_tonica(p):
    """Posicio de la tonica des del final (1=ultima), o None si es ambigua."""
    p = p.lower().strip()
    if any(ch in p for ch in ("'", "-", "’", ".", "ï")) and "ï" not in p:
        return None
    if any(ch in p for ch in ("'", "-", "’", ".")):
        return None
    if any(ch.isdigit() for ch in p):
        return None
    grups = vocal_a_acento(p)
    n = len(grups)
    if n == 0:
        return None
    # adverbis en -ment: hereten la tonica de l'adjectiu (una silaba mes)
    if p.endswith("ment") and len(p) > 6:
        base = p[:-4]
        gb = vocal_a_acento(base)
        for idx, g in enumerate(gb):
            if any(ch in ACENT for ch in g):
                return len(gb) - idx + 1
    # accent grafic?
    for idx, g in enumerate(grups):
        if any(ch in ACENT for ch in g):
            return n - idx
    # sense accent: regla general
    if n == 1:                       # monosíl·lab -> l'única síl·laba és tònica
        return 1
    if p[-1] in "sd":
        return None
    if p[-1] == "y":                 # company (plana) vs jersey (ambigua)
        return 2 if n >= 2 and not es_vocal(p[-2]) else None
    if p[-1] in VOCAL_TANCADA:
        return None
    if p[-1] in VOCAL_FINAL_PLANA or p[-1] in "e":
        return 2 if n >= 2 else 1
    return 1


def classe(p):
    pos = posicio_tonica(p)
    if pos is None:
        return None
    if pos == 1:
        return "agudes"
    if pos == 2:
        return "planes"
    if pos == 3:
        return "esdruixoles"
    return "sobresdruixoles"


def carrega(nom_cat):
    ruta = os.path.join(DADES, nom_cat + ".txt")
    paraules = []
    with open(ruta, encoding="utf-8") as f:
        for linia in f:
            if linia.strip().startswith("#"):
                continue
            for p in linia.split():
                paraules.append(unicodedata.normalize("NFC", p))
    vistos, unics = set(), []
    for p in paraules:
        k = p.lower()
        if k not in vistos:
            vistos.add(k)
            unics.append(p)
    return unics


def main():
    cats_fora = {c: [] for c in CATEGORIES}
    rebutjades = []
    swift = [
        "import Foundation",
        "",
        "// Arxiu generat amb tools/genera_diccionari.py.",
        "// Cada paraula ha estat verificada automaticament per la posicio",
        "// de la silaba tonica (regles ortografiques del catala).",
        "",
        "enum DiccionariLocal {",
        "    ",
        "    static var totes: [Paraula] {",
        "        agudes + planes + esdruixoles + sobresdruixoles",
        "    }",
    ]

    for cat in CATEGORIES:
        bones, dubtoses = [], []
        for p in carrega(cat):
            c = classe(p)
            if c == cat:
                bones.append(p)
            else:
                dubtoses.append((p, c))
        cats_fora[cat] = bones
        rebutjades.extend((cat, p, c) for p, c in dubtoses)

        swift.append("    ")
        swift.append("    // MARK: - %s (%d paraules)" %
                     (cat[0].upper() + cat[1:], len(bones)))
        swift.append("    static let %s: [Paraula] = [" % cat)
        ordenats = sorted(bones, key=lambda w: w.lower())
        fila = "        "
        for i, p in enumerate(ordenats):
            fragment = '"%s"%s' % (p, "," if i < len(ordenats) - 1 else "")
            if len(fila) + len(fragment) + 1 > 96 and fila.strip():
                swift.append(fila.rstrip())
                fila = "        "
            fila += fragment + " "
        if fila.strip():
            swift.append(fila.rstrip())
        swift.append("    ].map { Paraula(text: $0, tipus: %s, origen: .local) }"
                     % NOM_TIPUS[cat])

    swift.append("}")
    swift.append("")

    with open(SORTIDA, "w", encoding="utf-8") as f:
        f.write("\n".join(swift))

    total = sum(len(v) for v in cats_fora.values())
    print("=== Recapte per categoria ===")
    for cat in CATEGORIES:
        print("  %-18s %4d OK   %3d descartades" %
              (cat, len(cats_fora[cat]),
               sum(1 for c, p, cc in rebutjades if c == cat)))
    print("  %-18s %4d" % ("TOTAL", total))
    if rebutjades:
        print("\n=== Descartades ===")
        for cat, p, c in rebutjades:
            print("  [%s] %-26s -> %s" % (cat, p, c or "ambigua"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
