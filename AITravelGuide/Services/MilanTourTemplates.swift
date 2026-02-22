import Foundation

// MARK: - Template Data Structures

struct TemplateDiscoveryPoint {
    let name: String
    let description: String
    let searchQuery: String
    let iconSystemName: String

    init(name: String, description: String, searchQuery: String, iconSystemName: String = "eye.fill") {
        self.name = name
        self.description = description
        self.searchQuery = searchQuery
        self.iconSystemName = iconSystemName
    }
}

struct TemplateStop {
    let name: String
    let searchQuery: String
    let description: String
    let historicalNote: String?
    let tip: String?
    let durationMinutes: Int
    let iconType: String
    let walkingNarration: String?
    let discoveryPoints: [TemplateDiscoveryPoint]
}

struct TourTemplate {
    let id: String
    let tourName: String
    let tourDescription: String
    let category: TourCategory
    let narrativeThread: String
    let guidePersona: GuidePersona
    let stops: [TemplateStop]
    let isSkeleton: Bool // true = Claude enriches descriptions at runtime
}

// MARK: - Milan Tour Templates

enum MilanTourTemplates {

    static func template(for category: TourCategory) -> TourTemplate? {
        switch category {
        case .milanLastSupper: return lastSupperHighlights
        case .milanBrera: return breraFoodTour
        case .milanHidden: return hiddenCourtyards
        case .milanNavigli: return navigliEvening
        case .milanFashion: return fashionVintage
        case .milanCoffee: return coffeeCulture
        default: return nil
        }
    }

    // MARK: - Fully Curated Templates

    static let lastSupperHighlights = TourTemplate(
        id: "milan_last_supper",
        tourName: "Da Vinci's Milan: The Last Supper & Beyond",
        tourDescription: "Walk the path of Leonardo da Vinci through Milan's most iconic landmarks, from the Duomo's rooftop to the masterpiece that changed art forever.",
        category: .milanLastSupper,
        narrativeThread: "Follow Leonardo da Vinci's footsteps through Renaissance Milan — from the cathedral that inspired him, through the grand halls where he entertained dukes, to the refectory wall where he painted eternity.",
        guidePersona: GuidePersona(
            name: "Lucia",
            tagline: "Art historian & Renaissance enthusiast",
            voiceStyle: "passionate, scholarly but accessible, loves dramatic storytelling",
            greeting: "Buongiorno! I'm Lucia, and I've spent twenty years falling in love with Leonardo's Milan. Today I'll show you the city through his eyes.",
            signoff: "Grazie for walking through history with me. Leonardo would have approved of your curiosity!"
        ),
        stops: [
            TemplateStop(
                name: "Duomo di Milano",
                searchQuery: "Duomo di Milano cathedral",
                description: "Milan's Gothic cathedral took nearly six centuries to complete. Its forest of 135 spires and 3,400 statues makes it the largest church in Italy. Stand at the front and look up — the sheer ambition of this building set the tone for everything Milan would become.",
                historicalNote: "Construction began in 1386 under Gian Galeazzo Visconti. Leonardo da Vinci himself submitted a design for the central cupola in 1487, though it was never built.",
                tip: "The rooftop terraces offer the best view in Milan. Go early morning to avoid crowds — you can walk among the spires and see the Alps on clear days.",
                durationMinutes: 20,
                iconType: "landmark",
                walkingNarration: nil,
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Piazza del Duomo",
                        description: "Look down at the piazza floor — the geometric pattern radiates outward from the cathedral entrance, designed to draw your eye toward the facade. Notice how the square acts as an open-air living room for the city.",
                        searchQuery: "Piazza del Duomo Milano"
                    )
                ]
            ),
            TemplateStop(
                name: "Galleria Vittorio Emanuele II",
                searchQuery: "Galleria Vittorio Emanuele II Milano",
                description: "Step into Milan's stunning 19th-century shopping gallery — often called 'il salotto di Milano' (Milan's drawing room). The iron-and-glass roof soars above mosaic floors featuring the coats of arms of Italy's four capital cities.",
                historicalNote: "Opened in 1877, this was one of the world's first shopping malls. Architect Giuseppe Mengoni fell from the roof just days before the inauguration — some say he jumped, others that he slipped while inspecting his masterpiece.",
                tip: "Find the bull mosaic on the floor near the center. Tradition says spinning three times on the bull's... sensitive area brings good luck. The floor there is worn smooth by millions of heels.",
                durationMinutes: 15,
                iconType: "landmark",
                walkingNarration: "As you leave the Duomo, turn left and you'll see the grand triumphal arch entrance to the Galleria. This 50-meter-tall archway was designed to frame the cathedral behind you — look back for a perfect photo.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Campari Bar",
                        description: "Glance to your right as you enter — the red-accented Campari Bar has occupied this spot since 1867. This is where the Campari spritz was born. The Art Nouveau interior is worth a peek even if you don't stop.",
                        searchQuery: "Camparino in Galleria Milano",
                        iconSystemName: "cup.and.saucer.fill"
                    ),
                    TemplateDiscoveryPoint(
                        name: "Glass Cupola",
                        description: "Stop at the center octagon and look straight up. The iron-and-glass dome rises 47 meters above you — when it was built, this was cutting-edge technology. Notice the four lunette mosaics representing Europe, America, Africa, and Asia.",
                        searchQuery: "Galleria Vittorio Emanuele II centro Milano"
                    )
                ]
            ),
            TemplateStop(
                name: "Teatro alla Scala",
                searchQuery: "Teatro alla Scala Milano opera house",
                description: "The world's most famous opera house hides behind a modest neoclassical facade. Inside, the horseshoe auditorium with its six tiers of boxes has hosted premieres by Verdi, Puccini, and Rossini. Even the exterior tells a story of Milan's love affair with music.",
                historicalNote: "La Scala opened in 1778, built on the site of the church Santa Maria alla Scala. During WWII, it was heavily bombed. Milanese citizens prioritized rebuilding the opera house even before their own homes.",
                tip: "The museum entrance on the side lets you peek into the auditorium even without a performance ticket. If you want to see a show, check for last-minute gallery tickets — they're surprisingly affordable.",
                durationMinutes: 15,
                iconType: "entertainment",
                walkingNarration: "Exit the Galleria through the north end and you'll emerge into Piazza della Scala. The statue in the center is Leonardo da Vinci himself, standing with four of his students at his feet. La Scala faces you directly.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Leonardo da Vinci Monument",
                        description: "This 1872 statue shows Leonardo in a thoughtful pose, holding a book. The four figures at the base are his most talented pupils: Cesare da Sesto, Marco d'Oggiono, Giovanni Antonio Boltraffio, and Andrea Salaino.",
                        searchQuery: "Monumento a Leonardo da Vinci Piazza della Scala Milano"
                    )
                ]
            ),
            TemplateStop(
                name: "Castello Sforzesco",
                searchQuery: "Castello Sforzesco Milano",
                description: "This massive 15th-century fortress was the seat of Milan's ruling Sforza dynasty — and Leonardo's main patron Ludovico il Moro lived here. Leonardo spent 17 years in Milan under Sforza patronage, decorating rooms in this very castle.",
                historicalNote: "Leonardo painted the extraordinary Sala delle Asse ceiling here around 1498 — an intricate trompe-l'oeil of intertwined mulberry trees. He also designed the castle's defenses and a system of locks for the nearby canals.",
                tip: "The castle museums are free on Tuesdays after 2pm. Don't miss Michelangelo's last sculpture, the unfinished Rondanini Pietà, in its own dedicated hall.",
                durationMinutes: 20,
                iconType: "historical",
                walkingNarration: "Walk up Via Dante, a pedestrian boulevard lined with cafes and gelaterias. This elegant street was built in the late 1800s to connect La Scala with the castle. Imagine Leonardo walking this same path to meet Duke Ludovico Sforza.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Via Dante Street Performers",
                        description: "Via Dante often has street musicians and performers. The wide pedestrian avenue was designed for leisurely strolling — very different from the narrow medieval lanes it replaced.",
                        searchQuery: "Via Dante Milano",
                        iconSystemName: "music.note"
                    ),
                    TemplateDiscoveryPoint(
                        name: "Fountain of Piazza Castello",
                        description: "The large fountain in front of the castle is nicknamed 'the wedding cake' by locals. It's a popular meeting spot and makes for a dramatic foreground photo of the castle's Torre del Filarete.",
                        searchQuery: "Fontana Piazza Castello Milano"
                    )
                ]
            ),
            TemplateStop(
                name: "Santa Maria delle Grazie",
                searchQuery: "Santa Maria delle Grazie Milano",
                description: "This Renaissance church houses Leonardo da Vinci's 'The Last Supper' — arguably the most famous painting in the world. The fresco covers an entire wall of the former refectory, measuring 4.6 by 8.8 meters. Standing before it is a once-in-a-lifetime experience.",
                historicalNote: "Leonardo painted The Last Supper between 1495 and 1498. Unlike traditional fresco technique, he used experimental tempera and oil on dry plaster, which began deteriorating almost immediately. During WWII bombing in 1943, the refectory roof collapsed — but the wall with the painting miraculously survived, protected by sandbags.",
                tip: "Tickets sell out months in advance — book at least 2-3 months ahead. Only 25 people are allowed in for 15 minutes at a time. Arrive 20 minutes early. No flash photography, but regular photos are allowed.",
                durationMinutes: 25,
                iconType: "museum",
                walkingNarration: "From the castle, walk along Corso Magenta — one of Milan's most elegant streets. You're tracing the route Leonardo would have walked from the Sforza court to the Dominican convent where he spent years on his masterpiece.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Bar Magenta",
                        description: "This Art Nouveau cafe on Corso Magenta has been serving Milanese since 1907. The tiled floors and wooden bar are original. A perfect spot for a quick espresso before seeing The Last Supper.",
                        searchQuery: "Bar Magenta Corso Magenta Milano",
                        iconSystemName: "cup.and.saucer.fill"
                    ),
                    TemplateDiscoveryPoint(
                        name: "Santa Maria delle Grazie Cloister",
                        description: "Before entering the refectory, notice the beautiful Renaissance cloister to the left of the church. Bramante designed the church's tribune — the same architect who later designed St. Peter's Basilica in Rome.",
                        searchQuery: "Chiostro Santa Maria delle Grazie Milano",
                        iconSystemName: "camera.fill"
                    )
                ]
            )
        ],
        isSkeleton: false
    )

    static let breraFoodTour = TourTemplate(
        id: "milan_brera_food",
        tourName: "Brera Bites: A Milanese Food Journey",
        tourDescription: "Taste your way through Milan's most charming neighborhood — from century-old pastry shops to hidden trattorias where chefs still cook nonna's recipes.",
        category: .milanBrera,
        narrativeThread: "Discover how Milan's food tells the story of the city — from Austrian-influenced pastries to risotto alla milanese, each bite carries centuries of tradition. The Brera district, home to artists and bohemians, has always been where tradition meets creativity on the plate.",
        guidePersona: GuidePersona(
            name: "Marco",
            tagline: "Third-generation Milanese foodie",
            voiceStyle: "warm, enthusiastic, shares family stories and food memories",
            greeting: "Ciao! I'm Marco. My nonna ran a trattoria in Brera for forty years, and I grew up tasting everything this neighborhood has to offer. Prepare your appetite — we have serious eating to do!",
            signoff: "Grazie mille for eating with me! Remember — in Milan, we don't just eat to live, we live to eat. Buon appetito always!"
        ),
        stops: [
            TemplateStop(
                name: "Pasticceria Marchesi",
                searchQuery: "Pasticceria Marchesi Via Santa Maria alla Porta Milano",
                description: "Milan's oldest pastry shop, founded in 1824. The green-and-gold Art Nouveau interior feels like stepping into a jewel box. Their panettone is legendary — Milanese families have been ordering it for Christmas for nearly 200 years.",
                historicalNote: "The Marchesi family has passed down recipes for eight generations. Prada acquired the brand in 2014, but the recipes and artisan methods remain unchanged. Every panettone is still hand-shaped.",
                tip: "Order a brioche con crema and a caffè al banco (at the counter) — it's the classic Milanese breakfast. Standing at the bar is cheaper and more authentic than sitting at a table.",
                durationMinutes: 20,
                iconType: "restaurant",
                walkingNarration: nil,
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Pasticceria Marchesi Window Display",
                        description: "Before entering, admire the window — Marchesi changes their elaborate displays seasonally. The packaging design, with its signature green and gold, hasn't changed since the 1800s.",
                        searchQuery: "Pasticceria Marchesi Milano",
                        iconSystemName: "camera.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Pescheria da Claudio",
                searchQuery: "Pescheria da Claudio Brera Milano",
                description: "This tiny fish shop in the heart of Brera has been run by the same family since the 1950s. Despite being hundreds of kilometers from the coast, Milan has a proud seafood tradition thanks to ancient trade routes. Claudio personally selects fish at 4am every morning.",
                historicalNote: "Milan's canal system, the Navigli, once connected the city to Lake Maggiore and the Adriatic. Fresh fish arrived daily by boat — a tradition that gave Milan surprisingly excellent seafood for an inland city.",
                tip: "Ask for a small tasting of their crudo (raw fish) if they're preparing it. The sea bass carpaccio is extraordinary. Arrive before noon for the best selection.",
                durationMinutes: 15,
                iconType: "shopping",
                walkingNarration: "Walk up Via Brera, the neighborhood's main artery. Notice the cobblestones under your feet and the mix of art galleries, antique shops, and tiny restaurants. This is Milan's bohemian soul — artists have lived here since the Academy of Fine Arts opened in 1776.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Pinacoteca di Brera Entrance",
                        description: "Look up at the grand palazzo entrance — the bronze statue in the courtyard is Napoleon, depicted as a Roman god. He founded this gallery in 1809 to house art seized from churches. Today it rivals the Uffizi.",
                        searchQuery: "Pinacoteca di Brera Milano"
                    ),
                    TemplateDiscoveryPoint(
                        name: "Brera Street Art",
                        description: "Keep an eye on the walls of Via Fiori Chiari — local and international artists regularly paste up works here. Brera's art isn't just in the galleries.",
                        searchQuery: "Via Fiori Chiari Brera Milano",
                        iconSystemName: "paintbrush.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Mercato di Brera",
                searchQuery: "Mercato di Brera Via San Marco Milano",
                description: "This open-air market on Via San Marco brings together local producers every third Saturday. Even on regular days, the surrounding shops sell fresh produce, aged cheeses, and cured meats that tell the story of Lombardy's agricultural richness.",
                historicalNote: "Lombardy's Po Valley is Italy's most productive agricultural region. The risotto rice, Gorgonzola cheese, and bresaola you'll find here all come from within a few hours of Milan.",
                tip: "Look for Gorgonzola DOP — it was invented in the town of Gorgonzola, just 20km from Milan. Try both the dolce (creamy, mild) and piccante (sharp, crumbly) versions.",
                durationMinutes: 15,
                iconType: "shopping",
                walkingNarration: "Continue along Via Fiori Chiari, lined with antique dealers. On weekends, their wares spill onto the street in an impromptu market. Turn right onto Via San Marco toward the market area.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Orto Botanico di Brera",
                        description: "Through a gate next to the Pinacoteca, a hidden botanical garden has been cultivating medicinal plants since 1774. It's free, barely visited, and feels like a secret oasis in the city center.",
                        searchQuery: "Orto Botanico di Brera Milano",
                        iconSystemName: "leaf.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Trattoria Milanese",
                searchQuery: "Trattoria Milanese Via Santa Marta Milano",
                description: "This family-run trattoria has been serving classic Milanese cuisine since 1933. The risotto alla milanese — saffron-gold and impossibly creamy — is made the same way it has been for generations. The cotoletta alla milanese (the original breaded cutlet) is thick, bone-in, and magnificent.",
                historicalNote: "Risotto alla milanese gets its golden color from saffron, which arrived in Milan via Arab traders in the Middle Ages. Legend says a cathedral glassmaker who used saffron to tint yellow glass accidentally dropped some into a wedding risotto — and a classic was born.",
                tip: "Order the risotto alla milanese and the cotoletta. Don't rush — Milanese eat slowly. Ask for the ossobuco if they have it; traditionally it's served alongside the risotto.",
                durationMinutes: 30,
                iconType: "restaurant",
                walkingNarration: "Head south through the quieter streets behind the Pinacoteca. The narrow lanes here feel more like a village than a major city. This is where you'll find trattorias that haven't changed their menus in decades.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Milanese Courtyard",
                        description: "Watch for open portoni (large doorways) along Via Santa Marta. Peer through — many hide beautiful ringhiera courtyards with iron balconies and climbing plants, a uniquely Milanese architectural style.",
                        searchQuery: "Via Santa Marta Milano",
                        iconSystemName: "door.left.hand.open"
                    )
                ]
            ),
            TemplateStop(
                name: "Gelateria della Musica",
                searchQuery: "Gelateria della Musica Via Giovanni Enrico Pestalozzi Milano",
                description: "Every flavor here is named after a musician or music genre. The gelato is made fresh daily using only natural ingredients — no artificial colors, no powdered bases. The 'Vivaldi' (pistachio and white chocolate) and 'Jazz' (dark chocolate and orange) are sublime.",
                historicalNote: "Italian gelato differs from ice cream in having less fat and air, which makes it denser and more flavorful. Milan's gelato scene has exploded in recent years, with artisan gelaterie rivaling Rome and Florence.",
                tip: "Skip the whipped cream — the gelato is rich enough. Ask for a piccolo (small) with two flavors. The seasonal fruit sorbets are dairy-free and incredibly intense.",
                durationMinutes: 15,
                iconType: "restaurant",
                walkingNarration: "Walk south toward the Navigli district. The streets transition from Brera's elegant art-gallery feel to a more eclectic, youthful energy. You're heading to where Milan's sweet tooth meets musical soul.",
                discoveryPoints: []
            ),
            TemplateStop(
                name: "N'Ombra de Vin",
                searchQuery: "N'Ombra de Vin Via San Marco Milano",
                description: "Hidden in a former Augustinian refectory from the 1300s, this wine bar is a cathedral of Italian wines. Stone arches, candlelight, and over 3,000 labels — the aperitivo here is the perfect Milanese ritual to end a food tour.",
                historicalNote: "Aperitivo culture is sacred in Milan. Between 6-9pm, bars serve cocktails accompanied by generous spreads of food — olives, bruschetta, small sandwiches, pasta salads. It began in 1860s Milan when Gaspare Campari invented his famous bitter drink.",
                tip: "Order a Negroni Sbagliato — it was invented in Milan (at Bar Basso) when a bartender accidentally used prosecco instead of gin. Pair it with their tagliere of Lombard cheeses and salumi.",
                durationMinutes: 25,
                iconType: "restaurant",
                walkingNarration: "Circle back toward Via San Marco for the grand finale — aperitivo, Milan's most beloved daily ritual. The evening light filters through the narrow streets, and the city shifts from work mode to social mode.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "San Marco Church Bell Tower",
                        description: "The bell tower of San Marco church dates to the 1200s. Mozart stayed in the adjoining monastery during his first visit to Milan in 1770, when he was just 14 years old.",
                        searchQuery: "Chiesa di San Marco Milano",
                        iconSystemName: "bell.fill"
                    )
                ]
            )
        ],
        isSkeleton: false
    )

    static let hiddenCourtyards = TourTemplate(
        id: "milan_hidden_courtyards",
        tourName: "Milan's Secret Courtyards",
        tourDescription: "Push open unmarked doors and discover Renaissance palaces, hidden gardens, and architectural treasures that most tourists walk right past.",
        category: .milanHidden,
        narrativeThread: "Milan's greatest treasures hide behind closed doors. For centuries, noble families built inward — modest facades concealing spectacular courtyards. Today, these secret spaces tell the story of a city that values substance over show.",
        guidePersona: GuidePersona(
            name: "Francesca",
            tagline: "Architect & urban explorer",
            voiceStyle: "curious, conspiratorial, delights in revealing secrets",
            greeting: "Ciao! I'm Francesca. I've spent years pushing open every unmarked door in Milan. Today I'll show you what's hiding behind those anonymous facades — prepare to have your mind blown.",
            signoff: "Now you know Milan's best-kept secret: always push the door. Arrivederci, fellow explorer!"
        ),
        stops: [
            TemplateStop(
                name: "Palazzo Clerici",
                searchQuery: "Palazzo Clerici Via Clerici Milano",
                description: "Push through the unremarkable entrance on Via Clerici and prepare for sensory overload. The Gallery of Tapestries contains Tiepolo's breathtaking ceiling fresco — a swirling panorama of the four continents painted in 1741. The explosion of color and movement above you is staggering.",
                historicalNote: "Marshal Anton Giorgio Clerici commissioned Tiepolo, the greatest fresco painter of the 18th century, to decorate his palazzo. The 'Chariot of the Sun' fresco spans the entire 23-meter gallery ceiling. Napoleon later used this palazzo as his Milanese headquarters.",
                tip: "The palazzo is now home to ISPI (Institute for International Political Studies) and hosts occasional public events. Check their website for open days — or simply walk in during business hours and ask politely. The porters are usually welcoming.",
                durationMinutes: 15,
                iconType: "historical",
                walkingNarration: nil,
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Via Clerici Facade",
                        description: "Notice how plain the street facade is — just a regular-looking Milanese building. This deliberate modesty is pure Milan: don't show off on the outside, save the spectacle for those who step through the door.",
                        searchQuery: "Via Clerici Milano"
                    )
                ]
            ),
            TemplateStop(
                name: "Ca' Granda (Università Statale)",
                searchQuery: "Ca' Granda Università degli Studi Milano",
                description: "Originally Milan's main hospital built in 1456, this masterpiece by Filarete features a stunning Renaissance courtyard with elegant loggia on all four sides. The geometric perfection of the arched colonnades is mesmerizing — and most of Milan walks past without knowing it's there.",
                historicalNote: "The Ca' Granda operated as a hospital for over 400 years. It was revolutionary for its time: separate wards for men and women, running water, and cross-shaped layouts for ventilation. Since 1958, it's been the University of Milan's main building.",
                tip: "Walk through the main entrance on Via Festa del Perdono and into the central courtyard. It's a public university building, so you can freely explore. The inner garden courtyard is even more peaceful.",
                durationMinutes: 20,
                iconType: "historical",
                walkingNarration: "Head south from Palazzo Clerici through the business district. The transition from medieval lanes to 19th-century boulevards is sharp — Milan has always been a city of contrasts. Watch for grand doorways that seem too ornate for their ordinary buildings.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Filarete's Facade Detail",
                        description: "Before entering, look at the brick-and-stone facade — the alternating pattern and pointed-arch windows show a unique blend of Gothic and Renaissance that exists only in Lombardy. This style is called 'lombardo' and influenced architecture across northern Italy.",
                        searchQuery: "Ca' Granda facciata Milano",
                        iconSystemName: "building.2.fill"
                    ),
                    TemplateDiscoveryPoint(
                        name: "Crypt of San Bernardino alle Ossa",
                        description: "Just around the corner, this small church contains an ossuary chapel with walls entirely covered in human bones and skulls arranged in decorative patterns. It's macabre, free, and unforgettable.",
                        searchQuery: "San Bernardino alle Ossa Milano",
                        iconSystemName: "cross.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Palazzo Borromeo",
                searchQuery: "Palazzo Borromeo Piazza Borromeo Milano",
                description: "The Borromeo family — one of Milan's most powerful dynasties for 600 years — built this Gothic-Renaissance palazzo in the 1300s. The courtyard features original 15th-century frescoes of courtly games, remarkably preserved and full of vivid detail.",
                historicalNote: "The Borromeo family produced cardinals, saints (San Carlo Borromeo), and diplomats. They still own the Borromean Islands on Lake Maggiore. The palazzo frescoes show nobles playing tarocchi (tarot cards) and pallacorda (an early form of tennis).",
                tip: "The courtyard is sometimes locked but often open during business hours — the building houses offices. Look through the gate if closed; you can still see the frescoed loggia. Ring the bell and explain you'd like to see the cortile — Italians respect cultural curiosity.",
                durationMinutes: 15,
                iconType: "historical",
                walkingNarration: "Walk west through the narrow streets near Piazza Borromeo. These blocks are among the oldest in Milan — some walls date to the Roman era. The low buildings and tight lanes feel completely different from the grand boulevards just a few blocks away.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Roman Column Fragment",
                        description: "At the corner of Via Borromei and Via Santa Maria Podone, look for ancient stone fragments embedded in the building walls. These are recycled Roman ruins — Milan was the capital of the Western Roman Empire from 286 to 402 AD.",
                        searchQuery: "Via Borromei Milano",
                        iconSystemName: "clock.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Santa Maria presso San Satiro",
                searchQuery: "Santa Maria presso San Satiro Milano",
                description: "Bramante's masterpiece of architectural illusion. The church had no room for a proper apse, so Bramante created a stunning trompe-l'oeil: what appears to be a deep choir extending 9 meters behind the altar is actually a flat wall painted to look three-dimensional. Stand at the entrance and your eyes will refuse to believe the truth.",
                historicalNote: "Bramante created this fake perspective around 1482, making a surface only 97cm deep appear to extend many meters. It's considered one of the greatest architectural trompe-l'oeil ever created. The technique was revolutionary for the Renaissance.",
                tip: "Stand in the center of the nave and look at the apse — it looks completely real. Now walk to the side and watch the illusion collapse. The 'aha' moment is incredible. Free entry.",
                durationMinutes: 15,
                iconType: "landmark",
                walkingNarration: "Continue south on Via Torino, one of Milan's main shopping streets. Among the chain stores, watch for number 17-19 — you'll find the entrance to a church that contains one of the greatest optical illusions in all of architecture.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Via Torino Medieval Tower",
                        description: "At the intersection with Via Mazzini, look up — a medieval tower fragment pokes above the modern buildings. These torre-case (tower-houses) once dotted Milan like a forest of stone. Most were demolished, but fragments survive embedded in newer construction.",
                        searchQuery: "Via Torino centro Milano",
                        iconSystemName: "building.columns.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Palazzo Crivelli",
                searchQuery: "Palazzo Crivelli Via Pontaccio Milano",
                description: "This lesser-known Renaissance palazzo features a stunning ringhiera courtyard — the uniquely Milanese style with iron-railed balconies running around all four sides. Laundry might hang from upper floors; this is a living, breathing courtyard, not a museum piece. That's what makes it perfect.",
                historicalNote: "The ringhiera style evolved from medieval communal housing. Multiple families shared a courtyard, with external balconies providing access to upper-floor apartments. This design shaped Milanese social life for centuries — neighbors knew everyone's business.",
                tip: "If the portone (main door) is closed, wait for a resident to enter or exit and politely ask if you can peek at the courtyard. Most Milanese are proud of their cortili and happy to show them off.",
                durationMinutes: 15,
                iconType: "historical",
                walkingNarration: "Head north through Brera's quieter back streets. The Brera district is a treasure trove of hidden courtyards — nearly every building conceals one. Start watching for open portoni as you walk; the most ordinary-looking door might reveal the most extraordinary space.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Brera Ringhiera Houses",
                        description: "Along Via Pontaccio, several buildings have their doors propped open. Each reveals a different courtyard personality — some with gardens, some with fountains, some with just a beautiful play of light on old stone.",
                        searchQuery: "Via Pontaccio Brera Milano",
                        iconSystemName: "door.left.hand.open"
                    ),
                    TemplateDiscoveryPoint(
                        name: "Via Fiori Oscuri Name Plaque",
                        description: "The street name 'Via Fiori Oscuri' (Street of Dark Flowers) refers to the shady gardens of the former convent that once stood here. Milan's street names often preserve memories of buildings long demolished.",
                        searchQuery: "Via Fiori Oscuri Milano",
                        iconSystemName: "text.book.closed.fill"
                    )
                ]
            )
        ],
        isSkeleton: false
    )

    // MARK: - Skeleton Templates (Claude enriches at runtime)

    static let navigliEvening = TourTemplate(
        id: "milan_navigli_evening",
        tourName: "Navigli by Night: Canals, Cocktails & Culture",
        tourDescription: "Experience Milan's canal district as it comes alive in the evening — from aperitivo along the water to live music in converted warehouses.",
        category: .milanNavigli,
        narrativeThread: "The Navigli canals once carried marble for the Duomo and connected Milan to the sea. Today they carry a different energy — aperitivo glasses clinking, live music drifting from courtyards, and the reflections of centuries-old buildings dancing on the water.",
        guidePersona: GuidePersona(
            name: "Alessandro",
            tagline: "Night owl & canal district local",
            voiceStyle: "relaxed, witty, knows every bartender by name",
            greeting: "Ciao bella! I'm Alessandro, and the Navigli is my living room. Let me show you where the real Milan comes out to play after dark.",
            signoff: "The night is still young in the Navigli — enjoy wherever it takes you! Buona serata!"
        ),
        stops: [
            TemplateStop(
                name: "Darsena",
                searchQuery: "Darsena Milano Navigli",
                description: "Milan's historic port basin where the Naviglio Grande and Naviglio Pavese meet. Recently renovated, the waterfront promenade is the perfect starting point for an evening stroll along the canals.",
                historicalNote: "The Darsena was Milan's main port from the 1600s until the 1950s. Barges carried goods from the Po River and Lake Maggiore. The canal system, partly designed by Leonardo da Vinci, once made Milan a port city despite being 100km from the sea.",
                tip: "Grab a drink at one of the waterfront bars and watch the sunset reflect off the water. The west-facing position makes for spectacular golden hour light.",
                durationMinutes: 15,
                iconType: "viewpoint",
                walkingNarration: nil,
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Leonardo's Lock System",
                        description: "Look at the lock gates where the canals meet the Darsena. Leonardo da Vinci designed the mitre lock gate system still used in canals worldwide — and this is where he tested his designs.",
                        searchQuery: "Conca di Viarenna Milano"
                    )
                ]
            ),
            TemplateStop(
                name: "Naviglio Grande",
                searchQuery: "Naviglio Grande Milano vicolo dei Lavandai",
                description: "The oldest of Milan's canals, dating to 1177. Walk along the towpath past colorful buildings, artist studios, and antique shops. The Vicolo dei Lavandai (Washerwomen's Lane) preserves the old stone wash stations where women did laundry until the 1950s.",
                historicalNote: "The Naviglio Grande stretches 50km from the Ticino River to Milan. It took over a century to complete. The marble for the Duomo arrived on barges along this canal — a journey that took days.",
                tip: "The antique market on the last Sunday of each month transforms the canal banks into one of Italy's best flea markets. Arrive early for the best finds.",
                durationMinutes: 20,
                iconType: "landmark",
                walkingNarration: "Walk south along the Naviglio Grande canal. The evening light paints the building facades in warm tones. Notice how each building leans slightly differently — centuries of settling have given the canal a charmingly imperfect character.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Vicolo dei Lavandai",
                        description: "Duck into this tiny alley to see the old stone washing stations under a wooden roof. Women washed laundry here in canal water until surprisingly recently. The covered stone basins are perfectly preserved.",
                        searchQuery: "Vicolo dei Lavandai Milano",
                        iconSystemName: "camera.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Mag Cafè",
                searchQuery: "Mag Cafè Ripa di Porta Ticinese Milano",
                description: "A beloved local cocktail bar in a converted canal-side warehouse. The bartenders are mixology artists who create seasonal cocktails with Italian ingredients — think basil, bergamot, and Sicilian blood orange.",
                historicalNote: nil,
                tip: "Ask for their signature cocktail of the season. The outdoor seating along the canal is magical at night.",
                durationMinutes: 20,
                iconType: "entertainment",
                walkingNarration: "Continue along the canal's south bank. The bar and restaurant scene intensifies as you move deeper into the district. Watch for the flickering candlelight from the venues along the water.",
                discoveryPoints: []
            ),
            TemplateStop(
                name: "Chiesa di San Cristoforo sul Naviglio",
                searchQuery: "Chiesa di San Cristoforo sul Naviglio Milano",
                description: "Two medieval churches fused into one, sitting right on the canal bank. The older dates to the 1100s. At night, the illuminated facade reflecting in the still canal water is one of Milan's most atmospheric sights.",
                historicalNote: "San Cristoforo is the patron saint of travelers. Medieval boatmen would stop here to pray for safe passage before continuing their journey along the canal. The tradition of blessing travelers continues today.",
                tip: "If the church is open, step inside to see the 14th-century frescoes. Outside, the small bridge offers the best photo spot with the church reflecting in the canal.",
                durationMinutes: 10,
                iconType: "historical",
                walkingNarration: "Continue west along the Naviglio Grande. The bars thin out and the atmosphere becomes more residential and peaceful. You're heading to one of Milan's most photogenic spots.",
                discoveryPoints: []
            ),
            TemplateStop(
                name: "Naviglio Pavese",
                searchQuery: "Naviglio Pavese Milano ponte",
                description: "The younger sibling of Naviglio Grande, this canal leads south toward Pavia. The evening scene here is more relaxed and local — fewer tourists, more Milanese enjoying their nightly passeggiata along the water.",
                historicalNote: "The Naviglio Pavese was completed in 1819 and once featured 12 locks to handle the elevation change between Milan and Pavia. It was a major commercial waterway until the mid-20th century.",
                tip: "End the evening at one of the trattorias along Via Ascanio Sforza. The outdoor tables along the canal, candlelit and buzzing with conversation, are quintessential Milan.",
                durationMinutes: 15,
                iconType: "landmark",
                walkingNarration: "Loop back toward the Darsena and cross to the Naviglio Pavese side. The atmosphere shifts — this canal has a quieter, more residential character that gives you a glimpse of everyday Milanese life.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Street Art Murals",
                        description: "The walls along Naviglio Pavese feature some of Milan's best street art. Local and international artists regularly add new works. Keep an eye out for pieces by Italian artists like Blu and Millo.",
                        searchQuery: "Naviglio Pavese street art Milano",
                        iconSystemName: "paintbrush.fill"
                    )
                ]
            )
        ],
        isSkeleton: true
    )

    static let fashionVintage = TourTemplate(
        id: "milan_fashion_vintage",
        tourName: "Fashion Capital: From Runway to Vintage",
        tourDescription: "Explore Milan's fashion DNA — from the gilded ateliers of the Quadrilatero della Moda to vintage boutiques where you can score designer finds at a fraction of the price.",
        category: .milanFashion,
        narrativeThread: "Milan became the world's fashion capital not by accident but through centuries of textile mastery, artistic vision, and pure Milanese ambition. This tour traces fashion from its aristocratic origins to today's street style revolution.",
        guidePersona: GuidePersona(
            name: "Valentina",
            tagline: "Fashion journalist & vintage hunter",
            voiceStyle: "stylish, opinionated, encyclopedic knowledge of designers",
            greeting: "Ciao! I'm Valentina. I've covered Milan Fashion Week for fifteen years, and I know every hidden gem in this city's fashion scene. Let's discover the style that makes Milan, Milan.",
            signoff: "Remember — true Milanese style isn't about logos, it's about knowing the rules well enough to break them. Shop well!"
        ),
        stops: [
            TemplateStop(
                name: "Quadrilatero della Moda",
                searchQuery: "Via Montenapoleone Milano",
                description: "The most exclusive fashion district in the world. Via Montenapoleone, Via della Spiga, Via Manzoni, and Corso Venezia form a golden rectangle where every luxury brand has its flagship. Even window-shopping here is an experience in design perfection.",
                historicalNote: "The Quadrilatero became Milan's fashion center in the 1950s-60s when designers like Krizia, Missoni, and Valentino opened ateliers here, challenging Paris's fashion monopoly.",
                tip: "Via della Spiga is pedestrian-only and feels more intimate than busy Montenapoleone. Look up at the palazzo facades — many fashion houses occupy buildings that were once noble residences.",
                durationMinutes: 20,
                iconType: "shopping",
                walkingNarration: nil,
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Museo Bagatti Valsecchi",
                        description: "Hidden among the fashion boutiques, this palazzo-museum recreates a Renaissance noble home with stunning original furnishings. A perfect contrast to the modern luxury around it.",
                        searchQuery: "Museo Bagatti Valsecchi Milano",
                        iconSystemName: "building.columns.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "10 Corso Como",
                searchQuery: "10 Corso Como Milano",
                description: "The world's first concept store, founded by former Vogue Italia editor Carla Sozzani in 1990. A curated mix of fashion, art, design, and a beautiful garden cafe. This is where fashion meets culture.",
                historicalNote: "Carla Sozzani transformed a former garage into a cultural destination that spawned an entire retail category. The concept store model — blending commerce, art, and lifestyle — has been copied worldwide but never matched.",
                tip: "The rooftop garden cafe is a hidden oasis. The bookshop is one of Milan's best for photography, art, and design titles.",
                durationMinutes: 20,
                iconType: "shopping",
                walkingNarration: "Walk north from the Quadrilatero through Corso Como, a pedestrian street that bridges high fashion and street culture. The energy shifts from hushed luxury to creative buzz.",
                discoveryPoints: []
            ),
            TemplateStop(
                name: "Cavalli e Nastri",
                searchQuery: "Cavalli e Nastri Via Brera Milano vintage",
                description: "Milan's most curated vintage boutique, specializing in designer pieces from the 1920s through 1990s. Find original Pucci, Versace, and Missoni at a fraction of retail. The owners personally source every piece.",
                historicalNote: nil,
                tip: "Tell the staff your style and budget — they're incredibly knowledgeable and love helping customers find the perfect piece. Their accessories section (scarves, bags, jewelry) offers the best value.",
                durationMinutes: 20,
                iconType: "shopping",
                walkingNarration: "Head into the Brera neighborhood where vintage shopping thrives alongside art galleries. The contrast between million-euro Montenapoleone and treasure-hunt Brera is pure Milan.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Via Brera Gallery Windows",
                        description: "The art galleries along Via Brera often showcase fashion photography and design exhibitions alongside fine art. Fashion and art have always been inseparable in Milan.",
                        searchQuery: "Via Brera gallerie Milano",
                        iconSystemName: "paintpalette.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Armani/Silos",
                searchQuery: "Armani Silos Via Bergognone Milano",
                description: "Giorgio Armani's personal museum, housed in a converted 1950s granary. Four floors trace the designer's revolutionary impact on fashion — from deconstructed blazers to red carpet gowns. The minimalist space perfectly reflects Armani's aesthetic philosophy.",
                historicalNote: "Armani revolutionized fashion in the 1980s by deconstructing the power suit, removing padding and stiffness. He dressed Hollywood and changed how the world thought about elegance. This building is in the Tortona district, Milan's design hub.",
                tip: "The top floor often has special exhibitions. The ground-floor cafe and bookshop are accessible without a ticket.",
                durationMinutes: 25,
                iconType: "museum",
                walkingNarration: "Head south to the Tortona district, Milan's design and creative hub. During Fashion Week and Salone del Mobile, every warehouse here becomes a showroom. Even between events, the creative energy is palpable.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Tortona District Street Art",
                        description: "The Tortona district warehouses are canvases for large-scale murals. The industrial architecture and creative community make this Milan's most visually dynamic neighborhood.",
                        searchQuery: "Via Tortona Milano street art",
                        iconSystemName: "paintbrush.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "East Market Shop",
                searchQuery: "East Market Shop Via Battisti Milano",
                description: "A sprawling vintage and streetwear market in a converted industrial space. Hundreds of curated racks of vintage denim, sneakers, band tees, and designer deadstock. This is where Milan's fashion students and stylists shop.",
                historicalNote: nil,
                tip: "Visit on a Sunday when the full market is open with additional independent sellers. The sneaker section is particularly impressive — rare finds at reasonable prices.",
                durationMinutes: 20,
                iconType: "shopping",
                walkingNarration: "Head east to find where Milan's fashion future lives. The contrast from luxury Montenapoleone to streetwear and vintage tells the story of how fashion democratized — a revolution that started right here in Milan.",
                discoveryPoints: []
            )
        ],
        isSkeleton: true
    )

    static let coffeeCulture = TourTemplate(
        id: "milan_coffee_culture",
        tourName: "Milan Coffee Ritual: From Dawn to Dusk",
        tourDescription: "Discover why Milanese coffee culture is the original — from historic bars where espresso was perfected to the new wave of specialty roasters reshaping Italian caffè.",
        category: .milanCoffee,
        narrativeThread: "Italy didn't just adopt coffee — it reinvented it. Milan, as Italy's most cosmopolitan city, has always been at the forefront of caffè culture. From the standing espresso ritual to specialty third-wave shops, every cup tells a story of tradition meeting innovation.",
        guidePersona: GuidePersona(
            name: "Giulia",
            tagline: "Barista champion & coffee historian",
            voiceStyle: "energetic, passionate about detail, turns every cup into a story",
            greeting: "Buongiorno! I'm Giulia. I've pulled over 100,000 espressos in my career and I still get excited about the perfect crema. Let me show you coffee the way Milan invented it.",
            signoff: "May your crema always be perfect and your caffè always hot. Remember — in Milan, coffee is never just a drink, it's a moment. Alla prossima!"
        ),
        stops: [
            TemplateStop(
                name: "Caffè Cova",
                searchQuery: "Caffè Cova Via Montenapoleone Milano",
                description: "Founded in 1817 near La Scala, Cova has been the caffè of choice for Milan's elite for over two centuries. The wood-paneled interior, crystal chandeliers, and impeccable service make every espresso feel like an occasion.",
                historicalNote: "Cova was a meeting point for Italian patriots during the Risorgimento — revolutionary plans were hatched over tiny cups of espresso. The pastry counter has served its famous hazelnut cake since the 1800s.",
                tip: "Order your caffè al banco (at the bar) like a true Milanese — it's faster, cheaper, and more authentic. Standing at an Italian bar is a social experience, not a compromise.",
                durationMinutes: 15,
                iconType: "restaurant",
                walkingNarration: nil,
                discoveryPoints: []
            ),
            TemplateStop(
                name: "Camparino in Galleria",
                searchQuery: "Camparino in Galleria Milano",
                description: "Gaspare Campari opened this Art Nouveau bar in 1867, directly inside the Galleria. While famous for the bitter aperitivo that bears his name, the caffè here is equally ceremonial. The mosaic floors and carved woodwork transport you to Belle Époque Milan.",
                historicalNote: "The Campari company was born here. Gaspare Campari invented his signature bitter red drink using a secret recipe of herbs and spices that remains unchanged — and unknown — to this day.",
                tip: "Try a caffè corretto — espresso 'corrected' with a splash of grappa or sambuca. It's a classic Milanese pick-me-up, usually enjoyed in the afternoon.",
                durationMinutes: 15,
                iconType: "restaurant",
                walkingNarration: "Walk from Via Montenapoleone to the Galleria. You're tracing the daily route of Milanese businesspeople who've moved between these two caffè institutions for generations.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Galleria Ceiling Art",
                        description: "As you cross the Galleria, look up at the lunette paintings above the archways. Each depicts a continent through 19th-century European eyes — fascinating and revealing in equal measure.",
                        searchQuery: "Galleria Vittorio Emanuele II affreschi Milano"
                    )
                ]
            ),
            TemplateStop(
                name: "Pavé",
                searchQuery: "Pavé Via Felice Casati Milano",
                description: "The vanguard of Milan's specialty coffee movement. This tiny cafe-bakery sources single-origin beans, roasts them in-house, and prepares them with scientific precision. The croissants — baked on-site from midnight — are the best in the city.",
                historicalNote: nil,
                tip: "Order a flat white made with their Ethiopian single-origin and pair it with a cornetto al pistacchio. Ask the baristas about the beans — they love talking about their sourcing trips.",
                durationMinutes: 20,
                iconType: "restaurant",
                walkingNarration: "Leave the historic center and head to Porta Venezia, a diverse neighborhood where tradition-challenging specialty coffee took root. The journey from Cova to Pavé mirrors Italian coffee's evolution.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Porta Venezia Liberty Architecture",
                        description: "This neighborhood has Milan's finest Art Nouveau (Liberty style) buildings. Look up at the ornate facades on Via Malpighi — floral motifs, wrought iron balconies, and colorful ceramic tiles.",
                        searchQuery: "Via Malpighi Porta Venezia Milano Liberty",
                        iconSystemName: "building.2.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Orsonero Coffee",
                searchQuery: "Orsonero Coffee Via Broggi Milano",
                description: "Founded by a Korean-Italian couple, Orsonero brings world-class specialty coffee techniques to Milan. Their pour-over bar and carefully calibrated espressos have won multiple awards. This is where old-school Italian baristas come to see the future.",
                historicalNote: nil,
                tip: "Try their signature filter coffee alongside a traditional espresso — tasting both side by side reveals how different extraction methods transform the same bean.",
                durationMinutes: 15,
                iconType: "restaurant",
                walkingNarration: "Continue east through Porta Venezia. This multicultural neighborhood brings together Korean restaurants, African shops, and some of Milan's most innovative cafes — a perfect metaphor for how global influences enrich Italian coffee culture.",
                discoveryPoints: []
            ),
            TemplateStop(
                name: "Caffè Napoli",
                searchQuery: "Caffè Napoli Via Boccaccio Milano",
                description: "To understand Milanese coffee, you need to taste its rival. This Neapolitan-style bar serves espresso the southern way — darker roast, higher temperature, smaller cup, more intense. The friendly north-south coffee rivalry is one of Italy's great debates.",
                historicalNote: "The espresso machine was actually invented in Milan — Angelo Moriondo patented the first one in Turin in 1884, but it was Milanese manufacturer La Marzocco and later Faema that perfected and popularized the technology worldwide.",
                tip: "Order a caffè like they drink it in Naples and compare to the Milanese style you've been tasting. The difference is striking — both delicious, completely different philosophies.",
                durationMinutes: 15,
                iconType: "restaurant",
                walkingNarration: "Head west to taste the 'opposition.' Milan and Naples have debated coffee philosophy for decades — it's a rivalry as passionate as football. You're about to taste why both sides think they're right.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "La Marzocco Showroom",
                        description: "Keep an eye out for coffee equipment shops in this area. Milan is the global center of espresso machine manufacturing — brands like La Marzocco, Faema, and Cimbali all have roots here.",
                        searchQuery: "Via Boccaccio Milano",
                        iconSystemName: "gearshape.fill"
                    )
                ]
            )
        ],
        isSkeleton: true
    )
}
