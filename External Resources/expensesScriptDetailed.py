# ========== CONFIGURAȚIE ==========
# Modifica doar valorile din această secție

# Venituri
SALARIU_LUNAR_NET = 14303  # RON (după taxe)
CURS_EURO = 4.97

# Fonduri
FOND_URGENTA_CURENT = 37056  # RON - actualizat automat
# Fondul de urgență = 3x salariul lunar net (se calculează automat)

# Credit auto (se actualizează automat)
CREDIT_AUTO_REST = 52800.68  # RON - actualizat automat
CREDIT_AUTO_RATA_LUNARA = 2850  # RON - rata lunară totală (2699.56 + asigurare)

# Setări economii
SAVINGS_BOOST = True
SAVINGS_BOOST_MULTIPLIER = 3
SAVINGS_PERCENTAGE = 0.25

# Scenario switches
ENABLE_MEGA_EXPENSES = False  # concediu + cadouri
ENABLE_RENT = False  # în caz că te muți

# Mega expenses (activate cu ENABLE_MEGA_EXPENSES)
CONCEDIU = 4000
CADOURI = 3000

# Cheltuieli lunare (se convertesc automat în anuale)
CHELTUIELI_LUNARE = {
    'mancare': 3000,
    'benzina': 300,
    'abonament_sala': 200,
    'apple_music': 40,
    'youtube_premium': 40,
    'netflix': 0,
    'apple_icloud': 10,
    'tuns': 65,
    'random_expenses': 400,
    'cat_food': 400,
    'cat_litter': 100,
    'chirie': 0  # se activează cu ENABLE_RENT
}

# Cheltuieli anuale
CHELTUIELI_ANUALE = {
    'rata_masina': CREDIT_AUTO_RATA_LUNARA * 12,  # Se calculează din rata lunară
    'revizie_masina': 2000,
    'asigurare_masina': 2500,
    'impozit_auto': 250,
    'disney_plus': 370,
    'crunchyroll': 320,
    'genius': 100,
    'suplimente_sala': 500
}

# Configurare categorii pentru rapoarte (opțional - pentru grupare)
CATEGORII_CHELTUIELI = {
    'auto': {
        'lunare': ['benzina'],
        'anuale': ['rata_masina', 'asigurare_masina', 'impozit_auto', 'revizie_masina']
    },
    'subscriptii': {
        'lunare': ['apple_music', 'youtube_premium', 'netflix', 'apple_icloud'],
        'anuale': ['disney_plus', 'crunchyroll', 'genius']
    },
    'pisica': {
        'lunare': ['cat_food', 'cat_litter'],
        'anuale': []
    },
    'sala': {
        'lunare': ['abonament_sala'],
        'anuale': ['suplimente_sala']
    },
    'lifestyle': {
        'lunare': ['mancare', 'tuns', 'random_expenses'],
        'anuale': []
    },
    'locuinta': {
        'lunare': ['chirie'],
        'anuale': []
    }
}

# ========== FUNCȚII UTILE ==========

def yearValue(val):
    return val * 12
    
def monthValue(val):
    return val / 12

def format_suma(suma):
    """Formatează o sumă cu separator de mii"""
    return f"{suma:,.0f}".replace(",", " ")

def format_suma_euro(suma_ron):
    """Formatează suma în RON și EUR"""
    euro = suma_ron / CURS_EURO
    return f"{format_suma(suma_ron)} RON ({format_suma(euro)} EUR)"

def calculeaza_cheltuieli_totale():
    """Calculează automat toate cheltuielile (anuale)"""
    total_lunare_anuale = 0
    total_anuale = 0
    
    # Convertește cheltuielile lunare în anuale
    for key, value in CHELTUIELI_LUNARE.items():
        if key == 'chirie' and not ENABLE_RENT:
            continue
        total_lunare_anuale += yearValue(value)
    
    # Adaugă cheltuielile anuale
    for key, value in CHELTUIELI_ANUALE.items():
        total_anuale += value
    
    return total_lunare_anuale + total_anuale

def calculeaza_cheltuieli_pe_categorii():
    """Calculează cheltuielile grupate pe categorii"""
    categorii_totale = {}
    cheltuieli_fara_categorie = []
    
    for categorie, items in CATEGORII_CHELTUIELI.items():
        total_categorie = 0
        
        # Cheltuieli lunare din această categorie
        for item in items['lunare']:
            if item in CHELTUIELI_LUNARE:
                if item == 'chirie' and not ENABLE_RENT:
                    continue
                total_categorie += yearValue(CHELTUIELI_LUNARE[item])
        
        # Cheltuieli anuale din această categorie
        for item in items['anuale']:
            if item in CHELTUIELI_ANUALE:
                total_categorie += CHELTUIELI_ANUALE[item]
        
        categorii_totale[categorie] = total_categorie
    
    # Găsește cheltuielile care nu sunt în nicio categorie
    toate_items_categorii = set()
    for items in CATEGORII_CHELTUIELI.values():
        toate_items_categorii.update(items['lunare'])
        toate_items_categorii.update(items['anuale'])
    
    # Cheltuieli lunare fără categorie
    for key, value in CHELTUIELI_LUNARE.items():
        if key not in toate_items_categorii:
            if key == 'chirie' and not ENABLE_RENT:
                continue
            cheltuieli_fara_categorie.append((f"{key} (lunar)", yearValue(value)))
    
    # Cheltuieli anuale fără categorie
    for key, value in CHELTUIELI_ANUALE.items():
        if key not in toate_items_categorii:
            cheltuieli_fara_categorie.append((f"{key} (anual)", value))
    
    return categorii_totale, cheltuieli_fara_categorie

def get_top_cheltuieli(n=5):
    """Returnează top N cheltuieli (convertite în anual)"""
    toate_cheltuielile = []
    
    # Cheltuieli lunare convertite în anuale
    for key, value in CHELTUIELI_LUNARE.items():
        if key == 'chirie' and not ENABLE_RENT:
            continue
        toate_cheltuielile.append((key, yearValue(value), 'lunar'))
    
    # Cheltuieli anuale
    for key, value in CHELTUIELI_ANUALE.items():
        toate_cheltuielile.append((key, value, 'anual'))
    
    # Sortează descrescător după sumă
    toate_cheltuielile.sort(key=lambda x: x[1], reverse=True)
    
    return toate_cheltuielile[:n]

# ========== CALCULURI ==========

# Conversii
salary = yearValue(SALARIU_LUNAR_NET)
monthlySalary = SALARIU_LUNAR_NET

# Calculul intelligent al fondului de urgență
FOND_URGENTA_TINTA = monthlySalary * 3  # 3x salariul lunar net
fond_urgenta_complet = FOND_URGENTA_CURENT >= FOND_URGENTA_TINTA

# Calculul automat al cheltuielilor
yearlyExpenses = calculeaza_cheltuieli_totale()

# Mega expenses
megaExpenses = CONCEDIU + CADOURI
if ENABLE_MEGA_EXPENSES:
    yearlyExpenses += megaExpenses

monthlyExpenses = monthValue(yearlyExpenses)
baniLuna = monthlySalary - monthlyExpenses

# Calcul economii
savingsMultiplier = SAVINGS_PERCENTAGE * (SAVINGS_BOOST_MULTIPLIER if SAVINGS_BOOST else 1)
total_savings_potential = baniLuna * savingsMultiplier

# Logica inteligentă pentru alocarea economiilor
if not fond_urgenta_complet:
    # Dacă fondul de urgență nu e complet, calculăm inteligent
    fond_urgenta_lipseste = FOND_URGENTA_TINTA - FOND_URGENTA_CURENT
    
    if total_savings_potential >= fond_urgenta_lipseste:
        # Economiile din luna aceasta pot completa emergency fund-ul
        newSavings_emergency = fond_urgenta_lipseste
        newSavings_regular = total_savings_potential - fond_urgenta_lipseste
        newSavings = total_savings_potential  # Total pentru compatibilitate
        
        # Actualizăm statusul fondului pentru rapoarte
        fond_urgenta_va_fi_complet_luna_aceasta = True
    else:
        # Economiile nu ajung să completeze emergency fund-ul
        newSavings_emergency = total_savings_potential
        newSavings_regular = 0
        newSavings = newSavings_emergency
        fond_urgenta_va_fi_complet_luna_aceasta = False
else:
    # Dacă fondul de urgență e deja complet, totul merge în savings regular
    newSavings_emergency = 0
    newSavings_regular = total_savings_potential
    newSavings = newSavings_regular
    fond_urgenta_va_fi_complet_luna_aceasta = True

baniRamasiNou = baniLuna - total_savings_potential

def calculeaza_procente(total, *args):
    """Calculează procentele pentru fiecare categorie"""
    return [round((val / total) * 100, 1) for val in args]

def analiza_scenarii():
    """Compară diferite scenarii"""
    print("\n=== ANALIZA SCENARII ===")
    
    # Scenariul curent
    current_leftover = baniRamasiNou
    
    # Fără savings boost
    no_boost_savings = baniLuna * SAVINGS_PERCENTAGE
    no_boost_leftover = baniLuna - no_boost_savings
    
    # Cu mega expenses
    mega_monthly = monthValue(megaExpenses)
    with_mega_leftover = baniLuna - mega_monthly - newSavings
    
    print(f"Scenario actual: {format_suma(current_leftover)} RON rămas/lună")
    print(f"Fără boost economii: {format_suma(no_boost_leftover)} RON rămas/lună")
    print(f"Cu mega expenses: {format_suma(with_mega_leftover)} RON rămas/lună")
    
    # Analiza pragului de risc
    if current_leftover < 1000:
        print("⚠️  ATENȚIE: Bani rămași < 1000 RON/lună")
    elif current_leftover < 2000:
        print("⚡ MODERARE: Bani rămași < 2000 RON/lună")
    else:
        print("✅ HEALTHY: Buget sănătos")

def calculeaza_obiective():
    """Calculează progresul către obiective financiare"""
    print("\n=== PROGRES OBIECTIVE ===")
    
    # Fond urgență
    print(f"💰 FOND URGENȚĂ (3x salariul lunar):")
    print(f"Țintă: {format_suma(FOND_URGENTA_TINTA)} RON")
    print(f"Curent: {format_suma(FOND_URGENTA_CURENT)} RON")
    print(f"Progres: {(FOND_URGENTA_CURENT/FOND_URGENTA_TINTA)*100:.1f}%")
    
    if fond_urgenta_complet:
        print("✅ FOND URGENȚĂ COMPLET!")
        print("🎯 Acum economiile merg în savings regular")
    elif fond_urgenta_va_fi_complet_luna_aceasta:
        progres_dupa = ((FOND_URGENTA_CURENT + newSavings_emergency)/FOND_URGENTA_TINTA)*100
        print(f"🎉 FOND URGENȚĂ va fi COMPLET luna aceasta!")
        print(f"Progres după transfer: {progres_dupa:.1f}%")
        print(f"🚀 Savings regular se activează CHIAR LUNA ACEASTA cu {format_suma(newSavings_regular)} RON!")
    else:
        fond_urgenta_lipseste = FOND_URGENTA_TINTA - FOND_URGENTA_CURENT
        luni_urgenta = fond_urgenta_lipseste / newSavings_emergency if newSavings_emergency > 0 else float('inf')
        print(f"❌ Mai lipsesc: {format_suma(fond_urgenta_lipseste)} RON")
        if luni_urgenta != float('inf'):
            print(f"⏰ Completare în: {luni_urgenta:.1f} luni")
    
    # Credit auto
    luni_credit_ramase = CREDIT_AUTO_REST / CREDIT_AUTO_RATA_LUNARA
    ani_credit_ramasi = luni_credit_ramase / 12
    print(f"\n🚗 CREDIT AUTO:")
    print(f"Rest de plată: {format_suma(CREDIT_AUTO_REST)} RON")
    print(f"Rata lunară: {format_suma(CREDIT_AUTO_RATA_LUNARA)} RON")
    print(f"⏰ Se termină în: {luni_credit_ramase:.1f} luni ({ani_credit_ramasi:.1f} ani)")
    
    # Calculează data aproximativă când se termină
    from datetime import datetime, timedelta
    data_actuala = datetime.now()
    data_finalizare = data_actuala + timedelta(days=luni_credit_ramase * 30)
    print(f"📅 Finalizare estimată: {data_finalizare.strftime('%B %Y')}")
    
    # Impact după finalizarea creditului
    economii_extra_dupa_credit = CREDIT_AUTO_RATA_LUNARA
    economii_anuale_extra = yearValue(economii_extra_dupa_credit)
    print(f"💰 După finalizare: +{format_suma(economii_extra_dupa_credit)} RON/lună liberă")
    print(f"💎 Potențial economii extra: +{format_suma(economii_anuale_extra)} RON/an")
    
    # Economii regulare
    if fond_urgenta_complet or fond_urgenta_va_fi_complet_luna_aceasta:
        if newSavings_regular > 0:
            economii_anuale = yearValue(newSavings_regular)
            print(f"\n💎 SAVINGS REGULAR:")
            if fond_urgenta_va_fi_complet_luna_aceasta and not fond_urgenta_complet:
                print(f"Economii lunare (din luna aceasta): {format_suma(newSavings_regular)} RON")
            else:
                print(f"Economii lunare: {format_suma(newSavings_regular)} RON")
            print(f"Economii anuale estimate: {format_suma(economii_anuale)} RON")
    
    # Obiective suplimentare
    obiective = {
        "Vacanță": 8000,
        "Mașină nouă": 50000,
        "Apartament avans": 100000
    }
    
    savings_for_goals = newSavings_regular if (fond_urgenta_complet or fond_urgenta_va_fi_complet_luna_aceasta) else 0
    
    print(f"\n🎯 OBIECTIVE (cu savings regular):")
    if savings_for_goals > 0:
        for obiectiv, suma in obiective.items():
            luni_necesare = suma / savings_for_goals
            ani = luni_necesare / 12
            print(f"{obiectiv}: {ani:.1f} ani ({luni_necesare:.0f} luni)")
            
        # Obiective după finalizarea creditului (cu economii suplimentare)
        savings_dupa_credit = savings_for_goals + economii_extra_dupa_credit
        print(f"\n🚀 OBIECTIVE DUPĂ FINALIZAREA CREDITULUI (cu +{format_suma(economii_extra_dupa_credit)} RON/lună):")
        for obiectiv, suma in obiective.items():
            luni_necesare_dupa = suma / savings_dupa_credit
            ani_dupa = luni_necesare_dupa / 12
            print(f"{obiectiv}: {ani_dupa:.1f} ani ({luni_necesare_dupa:.0f} luni)")
    else:
        print("Vor fi disponibile după completarea fondului de urgență")

def analiza_optimizari():
    """Analizează bugetul și oferă sfaturi personalizate pentru optimizare"""
    print("\n" + "="*50)
    print("🧠 SFATURI PENTRU OPTIMIZAREA BUGETULUI")
    print("="*50)
    
    # Calcule pentru analiză
    economii_procent = (total_savings_potential / monthlySalary) * 100
    cheltuieli_procent = (monthlyExpenses / monthlySalary) * 100
    ramasi_procent = (baniRamasiNou / monthlySalary) * 100
    
    # Analiza top cheltuieli
    top_cheltuieli = get_top_cheltuieli(10)
    categorii_totale, _ = calculeaza_cheltuieli_pe_categorii()
    
    print(f"\n📊 ANALIZA CURENTĂ:")
    print(f"• Rata de economii: {economii_procent:.1f}%")
    print(f"• Cheltuieli: {cheltuieli_procent:.1f}%")
    print(f"• Bani flexibili: {ramasi_procent:.1f}%")
    
    # Info credit auto
    luni_credit_ramase = CREDIT_AUTO_REST / CREDIT_AUTO_RATA_LUNARA
    print(f"• Credit auto: {luni_credit_ramase:.1f} luni rămase")
    
    recomandari = []
    prioritate_alta = []
    prioritate_medie = []
    prioritate_scazuta = []
    
    # === ANALIZĂ RATA DE ECONOMII ===
    if economii_procent < 10:
        prioritate_alta.append("🚨 CRITIC: Rata de economii foarte scăzută! Țintește minim 10-15%")
    elif economii_procent < 20:
        prioritate_medie.append("⚠️ Rata de economii sub optim. Încearcă să ajungi la 20%+")
    elif economii_procent >= 30:
        prioritate_scazuta.append("🎉 Excelent! Rata de economii foarte bună!")
    
    # === ANALIZĂ FOND URGENȚĂ ===
    if not fond_urgenta_complet:
        progres_urgenta = (FOND_URGENTA_CURENT/FOND_URGENTA_TINTA)*100
        if fond_urgenta_va_fi_complet_luna_aceasta:
            prioritate_scazuta.append("🎉 Emergency fund se completează LUNA ACEASTA! Savings se activează!")
        elif progres_urgenta < 50:
            prioritate_alta.append("🚨 PRIORITATE: Completează fondul de urgență (sub 50%)")
        else:
            prioritate_medie.append("📈 Continuă să completezi fondul de urgență")
    
    # === ANALIZĂ TOP CHELTUIELI ===
    top_3_lunare = [(nume, monthValue(suma), tip) for nume, suma, tip in top_cheltuieli[:3]]
    
    print(f"\n🎯 ANALIZA CHELTUIELILOR MARI:")
    for i, (nume, suma_lunara, tip) in enumerate(top_3_lunare, 1):
        procent = (suma_lunara / monthlyExpenses) * 100
        print(f"{i}. {nume}: {format_suma(suma_lunara)} RON ({procent:.1f}%)")
        
        # Recomandări specifice pe cheltuială
        if nume == 'mancare' and suma_lunara > 2500:
            prioritate_medie.append(f"🍽️ Mâncare: {format_suma(suma_lunara)} RON/lună pare mult. Poți economisi 300-500 RON cu meal prep")
        
        if nume == 'benzina' and suma_lunara > 250:
            prioritate_scazuta.append(f"⛽ Benzină: {format_suma(suma_lunara)} RON/lună. Consideră carpooling sau transport public uneori")
        
        if nume == 'rata_masina':
            luni_ramase = CREDIT_AUTO_REST / CREDIT_AUTO_RATA_LUNARA
            if luni_ramase <= 12:
                prioritate_scazuta.append(f"🚗 Rata mașină se termină în {luni_ramase:.1f} luni! +{format_suma(suma_lunara)} RON/lună liberi!")
            else:
                prioritate_scazuta.append(f"🚗 Rata mașină: încă {luni_ramase:.1f} luni de plată")
        
        if 'subscript' in nume.lower() or 'netflix' in nume.lower() or 'spotify' in nume.lower():
            prioritate_scazuta.append(f"📺 Revizuiește subscripțiile - poți să împarți conturile cu familia/prietenii")
    
    # === ANALIZĂ CATEGORII ===
    if 'subscriptii' in categorii_totale:
        subscriptii_lunar = monthValue(categorii_totale['subscriptii'])
        if subscriptii_lunar > 300:
            prioritate_medie.append(f"📱 Subscripții: {format_suma(subscriptii_lunar)} RON/lună. Auditează ce folosești realmente")
    
    if 'auto' in categorii_totale:
        auto_lunar = monthValue(categorii_totale['auto'])
        auto_procent = (auto_lunar / monthlyExpenses) * 100
        if auto_procent > 25:
            prioritate_medie.append(f"🚗 Cheltuieli auto: {auto_procent:.1f}% din buget. Foarte mult pentru transport")
    
    # === ANALIZĂ SAVINGS BOOST ===
    if not SAVINGS_BOOST and baniRamasiNou > 2000:
        prioritate_scazuta.append("🚀 Ai destui bani rămași. Poți activa SAVINGS_BOOST pentru economii mai mari")
    
    # === RECOMANDĂRI GENERALE ===
    if ramasi_procent > 25:
        prioritate_medie.append("💰 Ai peste 25% bani rămași. Poți mări rata de economii!")
    elif ramasi_procent < 10:
        prioritate_alta.append("⚠️ Sub 10% bani rămași. Risc de deficit la cheltuieli neașteptate")
    
    # === RECOMANDĂRI AVANSATE ===
    
    # Calculează potențialul de optimizare
    potential_economii = 0
    
    # Estimări de economii posibile
    if 'mancare' in [item[0] for item in top_3_lunare]:
        mancare_suma = next(item[1] for item in top_3_lunare if item[0] == 'mancare')
        if mancare_suma > 2500:
            potential_economii += 400  # meal prep poate economisi 400 RON
    
    if 'subscriptii' in categorii_totale and monthValue(categorii_totale['subscriptii']) > 200:
        potential_economii += 100  # optimizare subscripții
    
    if potential_economii > 0:
        economii_suplimentare_an = yearValue(potential_economii)
        prioritate_medie.append(f"💡 Potențial de economii: ~{format_suma(potential_economii)} RON/lună ({format_suma(economii_suplimentare_an)} RON/an)")
    
    # === AFIȘARE RECOMANDĂRI ===
    
    if prioritate_alta:
        print(f"\n🚨 PRIORITATE MAXIMĂ:")
        for rec in prioritate_alta:
            print(f"   {rec}")
    
    if prioritate_medie:
        print(f"\n⚠️ PRIORITATE MEDIE:")
        for rec in prioritate_medie:
            print(f"   {rec}")
    
    if prioritate_scazuta:
        print(f"\n💡 SUGESTII GENERALE:")
        for rec in prioritate_scazuta:
            print(f"   {rec}")
    
    # === PLAN DE ACȚIUNE ===
    print(f"\n📋 PLAN DE ACȚIUNE (în ordine):")
    
    plan_actiuni = []
    
    if not fond_urgenta_complet and not fond_urgenta_va_fi_complet_luna_aceasta:
        plan_actiuni.append("1. 🎯 Completează fondul de urgență (prioritate #1)")
    elif fond_urgenta_va_fi_complet_luna_aceasta:
        plan_actiuni.append("1. 🎉 Completează emergency fund LUNA ACEASTA și activează savings!")
    
    if economii_procent < 15:
        plan_actiuni.append("2. 📈 Mărește rata de economii la minim 15%")
    
    if potential_economii > 200:
        plan_actiuni.append("3. 🔍 Optimizează cheltuielile mari (mancare, subscripții)")
    
    if ramasi_procent > 20:
        plan_actiuni.append("4. 💎 Transferă excesul în economii/investiții")
    
    # Plan pentru credit auto
    if luni_credit_ramase <= 24:
        plan_actiuni.append(f"5. 🚗 Pregătește-te pentru finalul creditului în {luni_credit_ramase:.0f} luni (+{format_suma(CREDIT_AUTO_RATA_LUNARA)} RON/lună)")
    
    if not plan_actiuni:
        plan_actiuni.append("🎉 Felicitări! Bugetul pare foarte bine optimizat!")
    
    for actiune in plan_actiuni:
        print(f"   {actiune}")
    
    # === CALCULATORUL DE SCENARII ===
    print(f"\n🎲 SIMULĂRI RAPIDE:")
    
    # Scenario 1: Reducere mâncare cu 300 RON
    if any(item[0] == 'mancare' for item in top_3_lunare):
        economii_extra = 300
        economii_noi = total_savings_potential + economii_extra
        economii_noi_procent = (economii_noi / monthlySalary) * 100
        print(f"📉 Dacă reduci mâncarea cu 300 RON: economii {economii_noi_procent:.1f}% (vs {economii_procent:.1f}%)")
    
    # Scenario 2: Mărire savings rate
    if economii_procent < 25:
        savings_nou = 0.25
        economii_25_procent = baniLuna * savings_nou
        ramasi_25 = baniLuna - economii_25_procent
        print(f"📈 Cu 25% economii: {format_suma(economii_25_procent)} RON economii, {format_suma(ramasi_25)} RON rămași")
    
    # Scenario 3: După finalizarea creditului
    if luni_credit_ramase > 0:
        economii_dupa_credit = total_savings_potential + CREDIT_AUTO_RATA_LUNARA
        economii_dupa_credit_procent = (economii_dupa_credit / monthlySalary) * 100
        print(f"🚗 După finalizarea creditului: {format_suma(economii_dupa_credit)} RON economii ({economii_dupa_credit_procent:.1f}%)")
    
    # === BENCHMARK-URI ===
    print(f"\n📏 BENCHMARK-URI FINANCIARE:")
    print(f"• Economii recomandate: 20-30% din venit")
    print(f"• Tu ai: {economii_procent:.1f}% {'✅' if economii_procent >= 20 else '❌'}")
    print(f"• Cheltuieli transport: max 15-20%")
    
    if 'auto' in categorii_totale:
        auto_procent = (monthValue(categorii_totale['auto']) / monthlySalary) * 100
        print(f"• Tu ai: {auto_procent:.1f}% {'✅' if auto_procent <= 20 else '❌'}")
    
    print(f"• Bani flexibili: minim 10-15%")
    print(f"• Tu ai: {ramasi_procent:.1f}% {'✅' if ramasi_procent >= 10 else '❌'}")
    
    # Savings status cu noua logică
    if fond_urgenta_complet or fond_urgenta_va_fi_complet_luna_aceasta:
        print(f"• Savings activ: ✅ {format_suma(newSavings_regular)} RON/lună")
    else:
        print(f"• Savings activ: ❌ (se activează după emergency fund)")

def quick_summary():
    """Sumar rapid pentru overview"""
    print("\n" + "="*50)
    print("📊 QUICK SUMMARY")
    print("="*50)
    
    economii_procent = (total_savings_potential / monthlySalary) * 100
    cheltuieli_procent = (monthlyExpenses / monthlySalary) * 100
    
    print(f"💰 Salariu: {format_suma(monthlySalary)} RON/lună")
    print(f"💸 Cheltuieli: {format_suma(monthlyExpenses)} RON ({cheltuieli_procent:.0f}%)")
    print(f"💎 Total economii: {format_suma(total_savings_potential)} RON ({economii_procent:.0f}%)")
    
    if not fond_urgenta_complet and not fond_urgenta_va_fi_complet_luna_aceasta:
        print(f"  ↳ 🚨 Emergency: {format_suma(newSavings_emergency)} RON")
        if newSavings_regular > 0:
            print(f"  ↳ 💰 Regular: {format_suma(newSavings_regular)} RON")
    elif fond_urgenta_va_fi_complet_luna_aceasta and not fond_urgenta_complet:
        print(f"  ↳ 🚨 Emergency: {format_suma(newSavings_emergency)} RON (completare fond)")
        print(f"  ↳ 🚀 Regular: {format_suma(newSavings_regular)} RON (ACTIVAT luna aceasta!)")
    else:
        print(f"  ↳ 💰 Savings regular: {format_suma(newSavings_regular)} RON")
    
    print(f"🎯 Rămas: {format_suma(baniRamasiNou)} RON")
    
    if ENABLE_MEGA_EXPENSES:
        print("🚨 MEGA EXPENSES ACTIVE")
    if SAVINGS_BOOST:
        print("🚀 SAVINGS BOOST ACTIVE")
    
    # Status fond urgență
    if fond_urgenta_complet:
        print("✅ FOND URGENȚĂ COMPLET")
    elif fond_urgenta_va_fi_complet_luna_aceasta:
        print("🎉 FOND URGENȚĂ se completează LUNA ACEASTA!")
    else:
        progres = (FOND_URGENTA_CURENT/FOND_URGENTA_TINTA)*100
        print(f"⏳ FOND URGENȚĂ: {progres:.0f}% complet")

def anual_print():
    print("\n=== RAPORT ANUAL DETALIAT ===")
    print(f"\nVENITURI:")
    print(f"Salariu anual: {format_suma(salary)} RON ({format_suma(salary / CURS_EURO)} EUR)")
    
    print("\nCHELTUIELI PRINCIPALE (pe categorii):")
    
    # Cheltuieli pe categorii
    categorii_totale, cheltuieli_fara_categorie = calculeaza_cheltuieli_pe_categorii()
    
    # Adaugă mega expenses dacă sunt activate
    if ENABLE_MEGA_EXPENSES:
        categorii_totale['mega_expenses'] = megaExpenses
    
    # Sortează categoriile după sumă
    categorii_sortate = sorted(categorii_totale.items(), key=lambda x: x[1], reverse=True)
    
    total = yearlyExpenses
    for categorie, suma in categorii_sortate:
        if suma > 0:  # Nu afișa categoriile cu 0
            procent = (suma / total) * 100
            categorie_display = categorie.replace('_', ' ').title()
            print(f"{categorie_display}: {format_suma(suma)} RON ({procent:.1f}%)")
    
    # Afișează cheltuielile fără categorie
    if cheltuieli_fara_categorie:
        print(f"\nCheltuieli individuale:")
        for nume, suma in cheltuieli_fara_categorie:
            procent = (suma / total) * 100
            print(f"{nume}: {format_suma(suma)} RON ({procent:.1f}%)")
    
    print(f"\nTotal cheltuieli anuale: {format_suma(yearlyExpenses)} RON")
    print(f"Total cheltuieli anuale: {format_suma(yearlyExpenses / CURS_EURO)} EUR")
    
    print(f"\nECONOMII ȘI BANI RĂMAȘI:")
    economii_anuale = yearValue(newSavings)
    bani_ramasi_an = salary - yearlyExpenses - economii_anuale
    print(f"Economii anuale: {format_suma(economii_anuale)} RON ({format_suma(economii_anuale / CURS_EURO)} EUR)")
    print(f"Bani rămași după economii: {format_suma(bani_ramasi_an)} RON/an")
    print(f"                           {format_suma(baniRamasiNou)} RON/lună")

def monthly_print():
    print("\n=== RAPORT LUNAR DETALIAT ===")
    
    if SAVINGS_BOOST:
        print("\n⚠️ SAVING BOOST ACTIVAT")
    if ENABLE_MEGA_EXPENSES:
        print("\n⚠️ MEGA EXPENSES ACTIVATE")
    
    print(f"\nVENITURI:")
    print(f"Salariu lunar: {format_suma(monthlySalary)} RON ({format_suma(monthlySalary / CURS_EURO)} EUR)")
    
    print("\nCHELTUIELI LUNARE (TOP 10):")
    
    # Folosește funcția get_top_cheltuieli pentru a afișa top cheltuielile
    top_cheltuieli = get_top_cheltuieli(10)
    
    for nume, suma_anuala, tip in top_cheltuieli:
        suma_lunara = monthValue(suma_anuala)
        procent = (suma_lunara / monthlyExpenses) * 100
        print(f"{nume} ({tip}): {format_suma(suma_lunara)} RON ({procent:.1f}%)")
    
    # Mega expenses
    if ENABLE_MEGA_EXPENSES:
        mega_lunare = monthValue(megaExpenses)
        procent = (mega_lunare / monthlyExpenses) * 100
        print(f"Cheltuieli mari (concediu + cadouri): {format_suma(mega_lunare)} RON ({procent:.1f}%)")
    
    print(f"\nTotal cheltuieli lunare: {format_suma(monthlyExpenses)} RON")
    
    print(f"\nECONOMII:")
    if not fond_urgenta_complet:
        print(f"💰 STRATEGIE: Completez fondul de urgență mai întâi")
        print(f"🚨 Emergency fund: {format_suma(newSavings_emergency)} RON/lună")
        if newSavings_regular > 0:
            print(f"💎 Savings regular: {format_suma(newSavings_regular)} RON/lună")
        print(f"Fond urgență curent: {format_suma(FOND_URGENTA_CURENT)} RON")
        print(f"Țintă fond urgență: {format_suma(FOND_URGENTA_TINTA)} RON (3x salariul)")
        
        if newSavings_emergency > 0:
            fond_urgenta_lipseste = FOND_URGENTA_TINTA - FOND_URGENTA_CURENT
            luni_ramase = fond_urgenta_lipseste / newSavings_emergency
            ani_ramasi = round(luni_ramase / 12, 1)
            print(f"Fond de urgență completat în: {luni_ramase:.1f} luni ({ani_ramasi} ani)")
    else:
        print(f"✅ FOND URGENȚĂ COMPLET!")
        print(f"💎 Toate economiile merg în savings regular: {format_suma(newSavings_regular)} RON/lună")
        economii_anuale = yearValue(newSavings_regular)
        print(f"📈 Economii anuale estimate: {format_suma(economii_anuale)} RON")

    print(f"\nBANI RĂMAȘI:")
    print(f"Bani rămași după economii: {format_suma(baniRamasiNou)} RON")

    # Analiza distribuției venitului
    economii_procent = (total_savings_potential / monthlySalary) * 100
    cheltuieli_procent = (monthlyExpenses / monthlySalary) * 100
    ramasi_procent = (baniRamasiNou / monthlySalary) * 100
    
    print(f"\nDISTRIBUȚIA VENITULUI:")
    print(f"Cheltuieli: {cheltuieli_procent:.1f}%")
    print(f"Economii: {economii_procent:.1f}%")
    if not fond_urgenta_complet and newSavings_emergency > 0:
        emergency_procent = (newSavings_emergency / monthlySalary) * 100
        regular_procent = (newSavings_regular / monthlySalary) * 100
        print(f"  ↳ Emergency: {emergency_procent:.1f}%")
        if newSavings_regular > 0:
            print(f"  ↳ Regular: {regular_procent:.1f}%")
    print(f"Bani rămași: {ramasi_procent:.1f}%")
    
    print("\nTOP 3 CHELTUIELI LUNARE:")
    for i, (nume, suma_anuala, tip) in enumerate(top_cheltuieli[:3], 1):
        suma_lunara = monthValue(suma_anuala)
        procent = (suma_lunara / monthlyExpenses) * 100
        print(f"{i}. {nume} ({tip}): {format_suma(suma_lunara)} RON ({procent:.1f}%)")

def planifica_transferuri_ing():
    """Calculează transferurile exacte pentru subconturile ING"""
    print("\n" + "="*50)
    print("🏦 PLANIFICAREA TRANSFERURILOR ING")
    print("="*50)
    
    # Calculează cheltuielile care rămân în contul principal (plăți automate)
    cheltuieli_principale = 0
    
    # Cheltuieli care se plătesc automat din contul principal
    cheltuieli_automate = [
        'rata_masina', 'asigurare_masina', 'impozit_auto', 'revizie_masina',  # auto
        'apple_music', 'youtube_premium', 'netflix', 'apple_icloud',  # subscripții
        'disney_plus', 'crunchyroll', 'genius',  # subscripții anuale
        'abonament_sala', 'suplimente_sala',  # sala
        'benzina', 'tuns', 'random_expenses', 'cat_food', 'cat_litter'  # alte cheltuieli
    ]
    
    # Calculează cheltuielile automate lunare
    for item in cheltuieli_automate:
        if item in CHELTUIELI_LUNARE:
            if item == 'chirie' and not ENABLE_RENT:
                continue
            cheltuieli_principale += CHELTUIELI_LUNARE[item]
        elif item in CHELTUIELI_ANUALE:
            cheltuieli_principale += monthValue(CHELTUIELI_ANUALE[item])
    
    # Adaugă mega expenses dacă sunt activate
    if ENABLE_MEGA_EXPENSES:
        cheltuieli_principale += monthValue(megaExpenses)
    
    # Calculează transferurile cu noua logică inteligentă
    transfer_joint = CHELTUIELI_LUNARE['mancare']  # Mâncarea merge în Joint
    
    # Folosește noua logică pentru emergency și savings
    if not fond_urgenta_complet:
        if fond_urgenta_va_fi_complet_luna_aceasta:
            # Emergency fund se completează luna aceasta ȘI savings se activează
            transfer_emergency = newSavings_emergency
            transfer_savings = newSavings_regular  # ACTIV chiar din luna aceasta!
        else:
            # Doar emergency fund
            transfer_emergency = newSavings_emergency
            transfer_savings = 0
    else:
        # Emergency fund deja complet
        transfer_emergency = 0
        transfer_savings = newSavings_regular
    
    # Banii personali = ce rămâne după toate transferurile
    transfer_personal = baniRamasiNou
    
    # Ce rămâne în contul principal după transferuri
    ramane_cont_principal = monthlySalary - transfer_joint - transfer_emergency - transfer_savings - transfer_personal
    
    print(f"\n💰 SALARIUL TĂU: {format_suma(monthlySalary)} RON")
    
    # Credit auto info
    luni_credit_ramase = CREDIT_AUTO_REST / CREDIT_AUTO_RATA_LUNARA
    print(f"🚗 CREDIT AUTO: {format_suma(CREDIT_AUTO_REST)} RON rămas ({luni_credit_ramase:.1f} luni)")
    
    print(f"\n📋 TRANSFERURI DE FĂCUT:")
    
    # Joint Account
    print(f"\n🍽️  JOINT (cont comun cu iubita):")
    print(f"   Transfer: {format_suma(transfer_joint)} RON")
    print(f"   Scop: Mâncare pentru amândoi")
    
    # Emergency Account
    if transfer_emergency > 0:
        print(f"\n🚨 EMERGENCY (fond urgență):")
        print(f"   Transfer: {format_suma(transfer_emergency)} RON")
        progres_dupa = ((FOND_URGENTA_CURENT + transfer_emergency) / FOND_URGENTA_TINTA) * 100
        print(f"   Progres după transfer: {progres_dupa:.1f}%")
        
        if fond_urgenta_va_fi_complet_luna_aceasta:
            print(f"   🎉 FONDUL va fi COMPLET după acest transfer!")
        else:
            luni_ramase = (FOND_URGENTA_TINTA - FOND_URGENTA_CURENT) / transfer_emergency
            print(f"   Fondul va fi complet în: {luni_ramase:.1f} luni")
    else:
        print(f"\n✅ EMERGENCY (complet):")
        print(f"   Transfer: 0 RON (fondul este deja complet)")
    
    # Savings Account - Logica corectată
    if transfer_savings > 0:
        print(f"\n💎 SAVINGS (economii regulate):")
        print(f"   Transfer: {format_suma(transfer_savings)} RON")
        economii_anuale = yearValue(transfer_savings)
        print(f"   Economii anuale: {format_suma(economii_anuale)} RON")
        
        if fond_urgenta_va_fi_complet_luna_aceasta and not fond_urgenta_complet:
            print(f"   🚀 SAVINGS se ACTIVEAZĂ chiar luna aceasta!")
            print(f"   (după completarea fondului de urgență)")
        elif fond_urgenta_complet:
            print(f"   💎 Savings deja activ")
    else:
        print(f"\n💎 SAVINGS:")
        if fond_urgenta_va_fi_complet_luna_aceasta:
            print(f"   Transfer: 0 RON (banii merg în emergency pentru completare)")
            print(f"   🚀 Se va activa LUNA VIITOARE cu toți banii!")
        else:
            print(f"   Transfer: 0 RON (se activează după completarea Emergency)")
    
    # Personal Account
    print(f"\n🎯 PERSONAL (bani flexibili):")
    print(f"   Transfer: {format_suma(transfer_personal)} RON")
    print(f"   Scop: Cheltuieli personale, ieșiri, shopping, etc.")
    
    # Cont Principal
    print(f"\n🏦 CONT PRINCIPAL (rămâne):")
    print(f"   Sumă rămasă: {format_suma(ramane_cont_principal)} RON")
    print(f"   Scop: Plăți automate (rate, subscripții, benzină, etc.)")
    print(f"   Include: Rata auto {format_suma(CREDIT_AUTO_RATA_LUNARA)} RON/lună")
    
    # Verificare matematică
    total_transferuri = transfer_joint + transfer_emergency + transfer_savings + transfer_personal + ramane_cont_principal
    
    print(f"\n🔍 VERIFICARE:")
    print(f"   Total transferuri + rămas: {format_suma(total_transferuri)} RON")
    print(f"   Salariu: {format_suma(monthlySalary)} RON")
    if abs(total_transferuri - monthlySalary) < 1:
        print("   ✅ Calculele se bat!")
    else:
        print("   ❌ EROARE în calcule!")
    
    # Instrucțiuni practice
    print(f"\n📱 INSTRUCȚIUNI PRACTICE (după primirea salariului):")
    print(f"1. 🍽️  Transfer către JOINT: {format_suma(transfer_joint)} RON")
    
    if transfer_emergency > 0:
        print(f"2. 🚨 Transfer către EMERGENCY: {format_suma(transfer_emergency)} RON")
    
    if transfer_savings > 0:
        transfer_nr = 3 if transfer_emergency > 0 else 2
        print(f"{transfer_nr}. 💎 Transfer către SAVINGS: {format_suma(transfer_savings)} RON")
        if fond_urgenta_va_fi_complet_luna_aceasta:
            print(f"   ⭐ PRIMUL transfer în savings! 🎉")
    
    final_nr = 3 + (1 if transfer_emergency > 0 else 0) + (1 if transfer_savings > 0 else 0)
    print(f"{final_nr}. 🎯 Transfer către PERSONAL: {format_suma(transfer_personal)} RON")
    print(f"{final_nr + 1}. 🏦 În PRINCIPAL rămân: {format_suma(ramane_cont_principal)} RON (pentru plăți automate)")
    
    # Sfaturi pentru organizare
    print(f"\n💡 SFATURI ORGANIZARE:")
    print(f"• Setează plățile automate din PRINCIPAL pentru:")
    print(f"  - Rate auto ({format_suma(CREDIT_AUTO_RATA_LUNARA)} RON/lună), asigurări, subscripții")
    print(f"  - Benzină (cu cardul principal)")
    print(f"  - Sală, tuns, cheltuieli pisică")
    
    print(f"• JOINT folosește-l pentru:")
    print(f"  - Cumpărături alimentare")
    print(f"  - Restaurants, delivery")
    
    print(f"• PERSONAL folosește-l pentru:")
    print(f"  - Shopping personal")
    print(f"  - Ieșiri cu prietenii")
    print(f"  - Hobby-uri, cărți, gadget-uri")
    print(f"  - Orice vrei fără să te simți vinovat! 😊")
    
    # Warning-uri
    if transfer_personal < 1000:
        print(f"\n⚠️  ATENȚIE: Bani personali puțini ({format_suma(transfer_personal)} RON)")
        print(f"   Consideră să optimizezi cheltuielile sau să mărești venitul")
    
    if ramane_cont_principal < cheltuieli_principale * 0.9:
        print(f"\n⚠️  ATENȚIE: S-ar putea să nu ajungă banii în PRINCIPAL")
        print(f"   Recomandare: Verifică plățile automate lunar")
    
    # Perspective de viitor
    if luni_credit_ramase <= 24:
        print(f"\n🚀 PERSPECTIVE VIITOARE:")
        print(f"   Credit auto se termină în {luni_credit_ramase:.1f} luni!")
        print(f"   Vei avea +{format_suma(CREDIT_AUTO_RATA_LUNARA)} RON/lună EXTRA pentru economii!")
        economii_dupa_credit = transfer_savings + CREDIT_AUTO_RATA_LUNARA
        print(f"   Savings vor crește la {format_suma(economii_dupa_credit)} RON/lună! 🎉")

def actualizeaza_valori_conturi():
    """Întreabă utilizatorul dacă a făcut transferurile și actualizează valorile"""
    print("\n" + "="*50)
    print("🔄 ACTUALIZARE AUTOMATĂ VALORI")
    print("="*50)
    
    # Afișează un sumar rapid al transferurilor sugerate
    print(f"\n📋 TRANSFERURILE SUGERATE PENTRU ACEASTĂ LUNĂ:")
    
    transfer_joint = CHELTUIELI_LUNARE['mancare']
    
    # Folosește aceeași logică ca în planifica_transferuri_ing
    if not fond_urgenta_complet:
        if fond_urgenta_va_fi_complet_luna_aceasta:
            transfer_emergency = newSavings_emergency
            transfer_savings = newSavings_regular  # ACTIV chiar din luna aceasta!
        else:
            transfer_emergency = newSavings_emergency
            transfer_savings = 0
    else:
        transfer_emergency = 0
        transfer_savings = newSavings_regular
        
    transfer_personal = baniRamasiNou
    
    print(f"🍽️  JOINT: +{format_suma(transfer_joint)} RON")
    if transfer_emergency > 0:
        print(f"🚨 EMERGENCY: +{format_suma(transfer_emergency)} RON")
    if transfer_savings > 0:
        print(f"💎 SAVINGS: +{format_suma(transfer_savings)} RON")
        if fond_urgenta_va_fi_complet_luna_aceasta and not fond_urgenta_complet:
            print(f"   ⭐ PRIMUL transfer în savings! Emergency fund se completează!")
    print(f"🎯 PERSONAL: +{format_suma(transfer_personal)} RON")
    
    # Info credit auto
    credit_nou_rest = CREDIT_AUTO_REST - CREDIT_AUTO_RATA_LUNARA
    print(f"\n🚗 CREDIT AUTO (actualizare automată):")
    print(f"Rest curent: {format_suma(CREDIT_AUTO_REST)} RON")
    print(f"După plata lunii: {format_suma(credit_nou_rest)} RON (-{format_suma(CREDIT_AUTO_RATA_LUNARA)} RON)")
    
    # Întreabă utilizatorul
    print(f"\n❓ Ai făcut transferurile sugerate?")
    print("1. Da, am făcut toate transferurile")
    print("2. Da, dar cu sume diferite (voi introduce manual)")
    print("3. Nu, nu am făcut transferurile încă")
    print("4. Skip - nu actualiza nimic")
    
    try:
        alegere = input("\nAlege o opțiune (1-4): ").strip()
        
        if alegere == "1":
            # Calculează noile valori automat
            nou_emergency = FOND_URGENTA_CURENT + transfer_emergency
            nou_savings = 200 + transfer_savings  # 200 este valoarea curentă menționată
            nou_personal = transfer_personal  # Se resetează la suma transferată
            nou_credit_rest = credit_nou_rest  # Scade rata lunară
            
            actualizeaza_fisier_cu_valori(nou_emergency, nou_savings, nou_personal, nou_credit_rest)
            
        elif alegere == "2":
            # Permite introducerea manuală
            print(f"\n📝 Introdu noile valori:")
            
            print(f"🚨 EMERGENCY curent: {format_suma(FOND_URGENTA_CURENT)} RON")
            try:
                nou_emergency = float(input(f"   Noua valoare EMERGENCY: ").replace(" ", "").replace(",", ""))
            except ValueError:
                nou_emergency = FOND_URGENTA_CURENT
                print("   Valoare invalidă, păstrez valoarea curentă")
            
            print(f"💎 SAVINGS curent: 200 RON")
            try:
                nou_savings = float(input(f"   Noua valoare SAVINGS: ").replace(" ", "").replace(",", ""))
            except ValueError:
                nou_savings = 200
                print("   Valoare invalidă, păstrez valoarea curentă")
            
            print(f"🎯 PERSONAL curent: 573 RON")
            try:
                nou_personal = float(input(f"   Noua valoare PERSONAL: ").replace(" ", "").replace(",", ""))
            except ValueError:
                nou_personal = 573
                print("   Valoare invalidă, păstrez valoarea curentă")
            
            print(f"🚗 CREDIT AUTO rest: {format_suma(CREDIT_AUTO_REST)} RON")
            print(f"   (se va scădea automat {format_suma(CREDIT_AUTO_RATA_LUNARA)} RON)")
            confirma_credit = input(f"   Scad rata din credit? (y/n): ").strip().lower()
            if confirma_credit in ['y', 'yes', 'da', '']:
                nou_credit_rest = credit_nou_rest
            else:
                nou_credit_rest = CREDIT_AUTO_REST
            
            actualizeaza_fisier_cu_valori(nou_emergency, nou_savings, nou_personal, nou_credit_rest)
            
        elif alegere == "3":
            print("\n⏳ OK, poți rula scriptul din nou după ce faci transferurile!")
            return False
            
        elif alegere == "4":
            print("\n⏭️  Skipping actualizarea...")
            return False
            
        else:
            print("\n❌ Opțiune invalidă, nu actualizez nimic")
            return False
            
    except KeyboardInterrupt:
        print("\n\n⏭️  Actualizare anulată")
        return False
    
    return True

def actualizeaza_fisier_cu_valori(nou_emergency, nou_savings, nou_personal, nou_credit_rest):
    """Actualizează fișierul Python cu noile valori"""
    import os
    
    fisier_path = __file__  # Calea către fișierul curent
    
    try:
        # Citește conținutul fișierului
        with open(fisier_path, 'r', encoding='utf-8') as f:
            continut = f.read()
        
        # Actualizează Emergency Fund
        import re
        continut = re.sub(
            r'FOND_URGENTA_CURENT = \d+(?:\.\d+)?.*',
            f'FOND_URGENTA_CURENT = {int(nou_emergency)}  # RON - actualizat automat',
            continut
        )
        
        # Actualizează Credit Auto Rest
        continut = re.sub(
            r'CREDIT_AUTO_REST = \d+(?:\.\d+)?.*',
            f'CREDIT_AUTO_REST = {nou_credit_rest:.2f}  # RON - actualizat automat',
            continut
        )
        
        # Scrie înapoi în fișier
        with open(fisier_path, 'w', encoding='utf-8') as f:
            f.write(continut)
        
        print(f"\n✅ ACTUALIZARE COMPLETĂ!")
        print(f"🚨 Emergency actualizat: {format_suma(nou_emergency)} RON")
        print(f"💎 Savings actualizat: {format_suma(nou_savings)} RON")
        print(f"🎯 Personal actualizat: {format_suma(nou_personal)} RON")
        print(f"🚗 Credit auto rest: {format_suma(nou_credit_rest)} RON")
        
        # Verifică dacă emergency fund-ul este acum complet
        if nou_emergency >= FOND_URGENTA_TINTA:
            print(f"\n🎉 FELICITĂRI! EMERGENCY FUND COMPLET!")
            print(f"💎 De luna viitoare toate economiile merg în SAVINGS!")
        
        # Verifică dacă creditul se apropie de final
        luni_ramase_credit = nou_credit_rest / CREDIT_AUTO_RATA_LUNARA
        if luni_ramase_credit <= 12:
            print(f"\n🎉 APROAPE GATA! Credit auto se termină în {luni_ramase_credit:.1f} luni!")
            print(f"💰 Vei avea +{format_suma(CREDIT_AUTO_RATA_LUNARA)} RON/lună liberi!")
        elif nou_credit_rest <= 0:
            print(f"\n🎉🎉🎉 FELICITĂRI! CREDITUL AUTO ESTE COMPLET PLĂTIT!")
            print(f"💰 Acum ai +{format_suma(CREDIT_AUTO_RATA_LUNARA)} RON/lună EXTRA pentru economii!")
        
        print(f"\n📝 Fișierul a fost actualizat automat!")
        print(f"🔄 Pentru a vedea noile calcule, rulează din nou scriptul:")
        print(f"   python3 expensesScriptDetailed.py")
        
        # Comentarii despre valorile care nu sunt în fișier (Savings și Personal)
        print(f"\n📋 NOTĂ: Valorile pentru SAVINGS și PERSONAL sunt doar informative")
        print(f"în această versiune. Emergency Fund și Credit Auto sunt actualizate în fișier.")
        
    except Exception as e:
        print(f"\n❌ EROARE la actualizarea fișierului: {e}")
        print(f"Poți actualiza manual în fișier:")
        print(f"FOND_URGENTA_CURENT = {int(nou_emergency)}")
        print(f"CREDIT_AUTO_REST = {nou_credit_rest:.2f}")

# ========== EXPORT JSON PENTRU APP ==========

def export_to_json():
    """Exportă datele pentru importul în aplicația Diameris iOS"""
    import json

    # Mapping categorii Python → App Category UUIDs (din Domain/Category.swift)
    CATEGORY_MAP = {
        'auto': 'D1A00001-0000-0000-0000-000000000001',        # autoTransport
        'subscriptii': 'D1A00002-0000-0000-0000-000000000002', # subscriptions
        'lifestyle': 'D1A00003-0000-0000-0000-000000000003',   # lifestyle
        'locuinta': 'D1A00004-0000-0000-0000-000000000004',    # housing
        'pisica': 'D1A00005-0000-0000-0000-000000000005',      # pets
        'sala': 'D1A00006-0000-0000-0000-000000000006',        # healthFitness
        'mancare': 'D1A00007-0000-0000-0000-000000000007',     # foodGroceries (special case)
    }

    # Mapping cheltuieli → iconițe SF Symbols
    ICON_MAP = {
        # Auto
        'benzina': 'fuelpump.fill',
        'rata_masina': 'creditcard.fill',
        'asigurare_masina': 'shield.checkered',
        'impozit_auto': 'doc.text.fill',
        'revizie_masina': 'wrench.and.screwdriver.fill',
        # Subscripții
        'apple_music': 'music.note',
        'youtube_premium': 'play.rectangle.fill',
        'netflix': 'tv.fill',
        'apple_icloud': 'icloud.fill',
        'disney_plus': 'sparkles.tv.fill',
        'crunchyroll': 'play.tv.fill',
        'genius': 'music.mic',
        # Pisică
        'cat_food': 'fork.knife',
        'cat_litter': 'leaf.fill',
        # Sală
        'abonament_sala': 'dumbbell.fill',
        'suplimente_sala': 'pill.fill',
        # Lifestyle
        'mancare': 'cart.fill',
        'tuns': 'scissors',
        'random_expenses': 'sparkles',
        # Locuință
        'chirie': 'house.fill',
    }

    # Găsește categoria pentru o cheltuială
    def get_category_for_expense(expense_key):
        for cat, items in CATEGORII_CHELTUIELI.items():
            if expense_key in items['lunare'] or expense_key in items['anuale']:
                # Special case: mancare e în lifestyle dar ar trebui să fie în foodGroceries
                if expense_key == 'mancare':
                    return CATEGORY_MAP.get('mancare')
                return CATEGORY_MAP.get(cat)
        return None

    # Nume mai frumoase pentru cheltuieli
    DISPLAY_NAMES = {
        'benzina': 'Benzină',
        'rata_masina': 'Rată mașină',
        'asigurare_masina': 'Asigurare auto',
        'impozit_auto': 'Impozit auto',
        'revizie_masina': 'Revizie mașină',
        'apple_music': 'Apple Music',
        'youtube_premium': 'YouTube Premium',
        'netflix': 'Netflix',
        'apple_icloud': 'iCloud Storage',
        'disney_plus': 'Disney+',
        'crunchyroll': 'Crunchyroll',
        'genius': 'Genius',
        'cat_food': 'Mâncare pisică',
        'cat_litter': 'Nisip pisică',
        'abonament_sala': 'Abonament sală',
        'suplimente_sala': 'Suplimente',
        'mancare': 'Mâncare',
        'tuns': 'Tuns',
        'random_expenses': 'Diverse',
        'chirie': 'Chirie',
    }

    expenses = []

    # Procesează cheltuielile lunare
    for key, value in CHELTUIELI_LUNARE.items():
        if key == 'chirie' and not ENABLE_RENT:
            continue
        if value == 0:
            continue

        expenses.append({
            'name': DISPLAY_NAMES.get(key, key.replace('_', ' ').title()),
            'amount': value,
            'frequency': 'monthly',
            'icon': ICON_MAP.get(key, 'banknote.fill'),
            'categoryId': get_category_for_expense(key),
            'isEnabled': True
        })

    # Procesează cheltuielile anuale
    for key, value in CHELTUIELI_ANUALE.items():
        if value == 0:
            continue

        expenses.append({
            'name': DISPLAY_NAMES.get(key, key.replace('_', ' ').title()),
            'amount': value,
            'frequency': 'annual',
            'icon': ICON_MAP.get(key, 'banknote.fill'),
            'categoryId': get_category_for_expense(key),
            'isEnabled': True
        })

    # Structura finală pentru export
    export_data = {
        'version': '1.0',
        'exportDate': __import__('datetime').datetime.now().isoformat(),
        'income': {
            'amount': SALARIU_LUNAR_NET,
            'frequency': 'monthly',
            'name': 'Salariu'
        },
        'savings': {
            'percentage': SAVINGS_PERCENTAGE,
            'boostEnabled': SAVINGS_BOOST,
            'boostMultiplier': SAVINGS_BOOST_MULTIPLIER
        },
        'emergencyFund': {
            'currentBalance': FOND_URGENTA_CURENT,
            'targetMultiplier': 3.0
        },
        'expenses': expenses
    }

    return json.dumps(export_data, indent=2, ensure_ascii=False)

# ========== EXECUȚIE ==========

if __name__ == "__main__":
    import sys
    import os

    # Check for --export flag
    if '--export' in sys.argv:
        json_output = export_to_json()

        # Save to file in the Diameris app resources folder
        script_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.dirname(script_dir)
        output_path = os.path.join(project_root, 'Diameris', 'Resources', 'expenses_import.json')

        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(json_output)

        print(f"✅ Exported to: {output_path}")
        print(f"📊 {len(__import__('json').loads(json_output)['expenses'])} expenses exported")
        sys.exit(0)

    # Quick overview
    quick_summary()
    
    # Analiză scenarii
    analiza_scenarii()
    
    # Progres obiective
    calculeaza_obiective()
    
    # Analiză optimizari
    analiza_optimizari()
    
    # Planificarea transferurilor ING
    planifica_transferuri_ing()
    
    # Rapoarte detaliate
    print("\n" + "="*50)
    monthly_print()
    
    print("\n" + "="*50)
    anual_print()
    
    # Tips finali
    print("\n" + "="*50)
    print("💡 TIPS:")
    print("- Modifică valorile din secțiunea CONFIGURAȚIE")
    print("- Adaugă noi cheltuieli în CHELTUIELI_LUNARE sau CHELTUIELI_ANUALE")
    print("- Actualizează CATEGORII_CHELTUIELI pentru gruparea în rapoarte")
    print("- Activează ENABLE_MEGA_EXPENSES pentru concedii")
    print("- Activează ENABLE_RENT dacă te muți")
    print("- Ajustează SAVINGS_PERCENTAGE dacă vrei să economisești mai mult/puțin")
    print("- Folosește secțiunea ING TRANSFERURI pentru organizarea banilor")
    
    # Actualizare automată valori (la sfârșitul scriptului)
    actualizeaza_valori_conturi()