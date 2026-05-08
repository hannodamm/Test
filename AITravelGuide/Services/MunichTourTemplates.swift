import Foundation

// MARK: - Munich Tour Templates

enum MunichTourTemplates {

    static func template(for category: TourCategory) -> TourTemplate? {
        switch category {
        case .munichOldTown: return oldTownHighlights
        case .munichBeer: return beerBreweryTour
        case .munichFood: return bavarianFoodTrail
        case .munichEnglishGarden: return englishGardenWalk
        case .munichRoyal: return royalMunich
        case .munichHidden: return hiddenMunich
        default: return nil
        }
    }

    // MARK: - Fully Curated Templates

    static let oldTownHighlights = TourTemplate(
        id: "munich_old_town",
        tourName: "Munich Old Town Highlights",
        tourDescription: "Explore the beating heart of Munich from the famous Glockenspiel at Marienplatz to the legendary Hofbrauhaus, passing Gothic churches, vibrant markets, and baroque gems along the way.",
        category: .munichOldTown,
        narrativeThread: "Walk through 800 years of Bavarian history in the Altstadt, where medieval guild halls stand next to baroque churches and the echoes of kings, monks, and brewers fill every cobblestoned lane.",
        guidePersona: GuidePersona(
            name: "Hans",
            tagline: "Historian with witty Bavarian humor",
            voiceStyle: "knowledgeable, warm, dry Bavarian wit, sprinkles in German phrases naturally",
            greeting: "Gruss Gott! I'm Hans, and I've been telling stories about this city for longer than I care to admit. Munich has more layers than a Baumkuchen, and today we'll peel them back together. Let's go!",
            signoff: "Pfiat di, my friend! You've walked the same stones as kings and brewers alike. Come back soon — Munich always has another story to tell."
        ),
        stops: [
            TemplateStop(
                name: "Marienplatz & Neues Rathaus",
                searchQuery: "Marienplatz Neues Rathaus Glockenspiel Munich",
                description: "Munich's central square has been the city's living room since 1158. The neo-Gothic Neues Rathaus dominates the north side, its facade crawling with gargoyles and statues. Every day at 11am (and noon and 5pm in summer), the famous Glockenspiel comes alive with 32 life-sized figures re-enacting scenes from Munich's history.",
                historicalNote: "The Glockenspiel's upper story depicts the 1568 wedding of Duke Wilhelm V. The lower level shows the Schafflertanz, a coopers' dance performed every seven years since 1517 to cheer citizens after a devastating plague. The next real performance is a cherished Munich tradition.",
                historicalFacts: [
                    HistoricalFact(year: "1158", title: "Munich's birthplace", content: "Henry the Lion founded Munich in 1158 by burning down a rival bishop's salt-trade bridge and rebuilding it on his land. Marienplatz was the new town's grain market — Munich grew up around this square.", category: .event),
                    HistoricalFact(year: "1908", title: "The Glockenspiel's debut", content: "The Glockenspiel was added to the Neues Rathaus tower in 1908. Its 32 life-sized figures act out a Wilhelm V wedding tournament and the Schäfflertanz coopers' dance, twice or three times daily.", category: .architecture),
                    HistoricalFact(year: "1517", title: "The dance after the plague", content: "Munich legend says the Schäfflertanz was first performed in 1517 by coopers who danced through plague-emptied streets to coax citizens back outside. They've performed it every seven years since.", category: .legend),
                    HistoricalFact(year: nil, title: "The Mariensäule's vow", content: "The golden Madonna on her column was raised in 1638 by a vow of Elector Maximilian I after Munich was spared during the Thirty Years' War. Distances from Munich to other Bavarian towns are still measured from this column.", category: .culture)
                ],
                tip: "Arrive ten minutes before the Glockenspiel show and face the Rathaus from the square's center for the best view. For a bird's-eye panorama, take the elevator up the Rathaus tower — far fewer crowds than most Munich viewpoints.",
                durationMinutes: 20,
                iconType: "landmark",
                walkingNarration: nil,
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Mariensaule Column",
                        description: "The golden Madonna atop this 11-meter column has watched over Munich since 1638, erected in gratitude after the city survived Swedish occupation and plague during the Thirty Years' War. It marks the exact center of the city.",
                        searchQuery: "Mariensaule Marienplatz Munich"
                    ),
                    TemplateDiscoveryPoint(
                        name: "Fischbrunnen Fountain",
                        description: "On Ash Wednesday, the Lord Mayor washes the city's purse in this fountain to ensure Munich's coffers stay full — a tradition dating back centuries. On market days, butchers used to keep their fish fresh here.",
                        searchQuery: "Fischbrunnen Marienplatz Munich",
                        iconSystemName: "drop.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Frauenkirche",
                searchQuery: "Frauenkirche Munich cathedral",
                description: "Munich's iconic twin-towered cathedral, the Frauenkirche, has defined the city's skyline since 1488. Its distinctive copper onion domes — added in 1525 because the original Gothic spires were never completed — are visible from miles around. Step inside to find a vast, surprisingly bright hall church that can hold 20,000 worshippers.",
                historicalNote: "Just inside the entrance, look for the Teufelstritt — the Devil's Footprint. Legend says the Devil visited the church and, seeing no windows from where he stood, laughed that the architect had built a church without light. But the architect had cleverly hidden the windows behind pillars. When the Devil realized the trick, he stamped his foot in rage, leaving the mark you see today.",
                historicalFacts: [
                    HistoricalFact(year: "1488", title: "Built in twenty years", content: "Master Jörg von Halsbach raised the Frauenkirche in just twenty years (1468–1488). Brick was used instead of stone because it was cheaper and faster — and Munich could afford no delay.", category: .architecture),
                    HistoricalFact(year: nil, title: "The onion-dome silhouette", content: "The two domed towers were a temporary measure waiting for proper Gothic spires that never came. The 'onion domes' became the silhouette of Munich — by ordinance no building in the historic centre may rise higher than the Frauenkirche.", category: .culture),
                    HistoricalFact(year: nil, title: "The Devil's Footprint", content: "Step into the entrance and look at the marble floor: a black footprint marks the spot where, legend says, the Devil stamped his foot in rage when he realised the architect had hidden the windows behind pillars to trick him into thinking the church had none.", category: .legend),
                    HistoricalFact(year: "1944", title: "Bombed but not lost", content: "Allied bombs gutted the interior in 1944 and badly damaged both towers. The cathedral reopened in 1953 — Munich rebuilt it with deliberate restraint, leaving the masonry rougher than before, as a quiet reminder.", category: .event)
                ],
                tip: "Stand on the Devil's Footprint and look forward — you truly cannot see any windows from that spot. Then step to the side and the light floods in. It's a brilliant piece of architectural trickery. The south tower offers stunning views when open.",
                durationMinutes: 20,
                iconType: "landmark",
                walkingNarration: "From Marienplatz, walk west along the pedestrian zone. Within a minute you'll see the massive brick towers of the Frauenkirche rising above the rooftops. A city ordinance still forbids any building in central Munich from being taller than its 99-meter towers.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Frauenkirche Emperor's Tomb",
                        description: "In the choir, an ornate black marble cenotaph marks the tomb of Holy Roman Emperor Ludwig IV (Ludwig the Bavarian), who made Munich an imperial residence in the 14th century. The elaborate tomb was added 200 years after his death.",
                        searchQuery: "Frauenkirche Emperor Ludwig tomb Munich"
                    )
                ]
            ),
            TemplateStop(
                name: "Viktualienmarkt",
                searchQuery: "Viktualienmarkt Munich market",
                description: "Munich's beloved open-air food market has been feeding the city since 1807. Over 140 stalls sell everything from Alpine cheese and Bavarian sausages to exotic spices and fresh flowers. The central beer garden, shaded by chestnut trees, rotates through Munich's six major breweries so every brew gets its turn.",
                historicalNote: "The market moved here from Marienplatz when it outgrew the square. Each of the six maypole-like fountains honors a different Bavarian folk character. The market survived WWII bombing and post-war modernization attempts — Munchners refused to let anyone touch their Viktualienmarkt.",
                historicalFacts: [
                    HistoricalFact(year: "1807", title: "Outgrew the main square", content: "King Max Joseph moved the food market off Marienplatz in 1807 because farmers' carts and shoppers were swallowing the city's central plaza. The new site became the Viktualienmarkt — 'food market.'", category: .event),
                    HistoricalFact(year: nil, title: "Six fountains for six clowns", content: "Each of the six maypole-like fountains honours a Munich folk character — Karl Valentin, Liesl Karlstadt, Weiss Ferdl, Roider Jackl, Ida Schumacher, and Elise Aulinger. Munich's love of stage comedy is built into the market itself.", category: .culture),
                    HistoricalFact(year: nil, title: "Hereditary stalls", content: "Many stalls are run by families who hold their licenses by inheritance. Losing your Viktualienmarkt stall is considered a greater family tragedy than losing your apartment.", category: .culture)
                ],
                tip: "Try a Leberkassemmel (a thick slice of warm Leberkase in a crusty roll) from one of the butcher stalls — it's Munich's favourite street food. Wash it down with a Mass (liter) of beer at the Biergarten. Locals bring their own food and just buy the beer, which is perfectly acceptable.",
                durationMinutes: 25,
                iconType: "shopping",
                walkingNarration: "Head south from the Frauenkirche through the narrow lanes. You'll smell the Viktualienmarkt before you see it — roasting nuts, fresh herbs, and grilled sausages wafting through the streets. Follow your nose.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Karl Valentin Fountain",
                        description: "Look for the small fountain honoring Karl Valentin, Munich's beloved comedian and the 'Bavarian Charlie Chaplin.' His absurdist humor still shapes Munich's comic identity. Locals leave flowers here on his birthday.",
                        searchQuery: "Karl Valentin Brunnen Viktualienmarkt Munich",
                        iconSystemName: "theatermasks.fill"
                    ),
                    TemplateDiscoveryPoint(
                        name: "Schmalznudel Stand Nearby",
                        description: "Just off the market's northwest corner sits Cafe Frischhut, where the legendary Schmalznudel — a pillowy, sugar-dusted fried dough — has been made fresh since 1973. The queue is always worth it.",
                        searchQuery: "Cafe Frischhut Schmalznudel Munich",
                        iconSystemName: "cup.and.saucer.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Asamkirche",
                searchQuery: "Asamkirche Sendlinger Strasse Munich",
                description: "Squeezed into a row of shops on Sendlinger Strasse, this tiny late-baroque masterpiece explodes with color and drama the moment you step inside. Built by the Asam brothers as their private chapel between 1733 and 1746, every square centimeter is covered in frescoes, gilded stucco, and theatrical lighting effects.",
                historicalNote: "Cosmas Damian and Egid Quirin Asam were master artists who designed the church entirely for themselves — Egid Quirin even lived in the house next door and had a private window looking directly at the altar. The citizens of Munich protested until the brothers agreed to open it to the public.",
                historicalFacts: [
                    HistoricalFact(year: "1733", title: "A private chapel for two brothers", content: "Cosmas Damian and Egid Quirin Asam — a painter and a sculptor — built this church between 1733 and 1746 next to their houses for their personal devotion. Public protest forced them to open it.", category: .event),
                    HistoricalFact(year: nil, title: "Late Bavarian Baroque concentrated", content: "Only nine metres wide, the Asamkirche packs every Baroque trick into one room: gilded stucco, ceiling frescoes, marbled columns, dramatic side-lighting. It's considered the finest small Baroque interior in southern Germany.", category: .architecture),
                    HistoricalFact(year: nil, title: "The window from the bedroom", content: "Egid Quirin Asam's house next door had a small private window looking onto the high altar so he could attend Mass without leaving home. The window is still visible from inside the church.", category: .culture)
                ],
                tip: "The church is free and tiny — you can see everything in ten minutes, but you'll want to linger. The way natural light enters through hidden windows to illuminate the altar is pure theatrical genius. Visit in the morning when sunlight hits the interior at its best.",
                durationMinutes: 15,
                iconType: "landmark",
                walkingNarration: "Walk south down Sendlinger Strasse, one of Munich's oldest shopping streets. The Asamkirche hides in plain sight — you'll walk right past it if you don't know to look for the ornate facade squeezed between ordinary storefronts.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Asam Brothers' House",
                        description: "Immediately to the left of the church, notice the richly decorated house facade — this was Egid Quirin Asam's personal residence. He designed it so he could gaze at the high altar from his bedroom window.",
                        searchQuery: "Asamhaus Sendlinger Strasse Munich"
                    )
                ]
            ),
            TemplateStop(
                name: "Odeonsplatz",
                searchQuery: "Odeonsplatz Theatinerkirche Feldherrnhalle Munich",
                description: "This grand square marks where Munich's medieval old town meets its royal boulevard. The mustard-yellow Theatinerkirche, with its exuberant Italian baroque facade, faces the Feldherrnhalle, a monumental loggia modeled on Florence's Loggia dei Lanzi. Together they create one of Germany's most photogenic squares.",
                historicalNote: "The Feldherrnhalle has witnessed pivotal moments in German history. In 1923, Hitler's Beer Hall Putsch ended here when police opened fire on the marching Nazis. A small plaque on the east side of the hall commemorates the four policemen who died stopping the coup. During the Nazi era, citizens who refused to salute the memorial would detour through Viscardigasse — now called Druckebergergasse (Shirkers' Lane).",
                historicalFacts: [
                    HistoricalFact(year: "1844", title: "A loggia for Bavaria's generals", content: "Ludwig I commissioned Friedrich von Gärtner to build the Feldherrnhalle in 1844, modelled on the Loggia dei Lanzi in Florence. The two bronze statues honour Bavarian field marshals Tilly and Wrede.", category: .architecture),
                    HistoricalFact(year: "1923", title: "Where the Beer Hall Putsch died", content: "On 9 November 1923, Bavarian state police halted Hitler's marching Nazis here with a brief volley of fire. Four policemen and sixteen putschists died; Hitler was arrested and tried. He used the trial to launch his political career.", category: .event),
                    HistoricalFact(year: nil, title: "Shirkers' Lane", content: "After 1933, the Nazis turned the spot into a memorial that passers-by were forced to salute. Munich citizens who refused detoured down the narrow Viscardigasse behind the hall. It earned the nickname Drückebergergasse — 'Shirkers' Lane.'", category: .legend),
                    HistoricalFact(year: "1597", title: "The Theatinerkirche next door", content: "Across the square, the bright-yellow Theatinerkirche was built starting in 1663 to celebrate the birth of an heir to Elector Ferdinand Maria. Its all-white Italian-Baroque interior is one of the loveliest in Germany.", category: .general)
                ],
                tip: "Walk through to the Hofgarten behind the Feldherrnhalle for a peaceful escape. The Renaissance garden with its central temple and arched walkways is one of Munich's most relaxing spots.",
                durationMinutes: 15,
                iconType: "historical",
                walkingNarration: "Head north through the old town toward Odeonsplatz. As the narrow medieval streets suddenly open up into this vast, elegant square, you'll feel the shift from medieval Munich to the royal capital the Wittelsbachs built.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Viscardigasse (Shirkers' Lane)",
                        description: "Look for the narrow alley on the east side of the Feldherrnhalle. During the Nazi era, a memorial here required all passers-by to give the Hitler salute. Brave Munchners would duck through this alley instead. Bronze footprints embedded in the pavement now honor their quiet resistance.",
                        searchQuery: "Viscardigasse Druckebergergasse Munich",
                        iconSystemName: "figure.walk"
                    ),
                    TemplateDiscoveryPoint(
                        name: "Theatinerkirche Interior",
                        description: "Step inside the Theatinerkirche for a dazzling all-white stucco interior — a stunning contrast to its colorful exterior. The church was built in 1663 to celebrate the birth of a Wittelsbach heir. The royal crypt below holds members of the dynasty.",
                        searchQuery: "Theatinerkirche interior Munich"
                    )
                ]
            ),
            TemplateStop(
                name: "Hofbrauhaus",
                searchQuery: "Hofbrauhaus am Platzl Munich",
                description: "The world's most famous beer hall has been pouring since 1589, when Duke Wilhelm V founded it as the royal court brewery. The cavernous Schwemme (ground-floor hall) seats 1,300, the oompah band never stops, and the ceiling frescoes have absorbed centuries of beer-fueled merriment. It's loud, it's lively, and it's unmissably Munich.",
                historicalNote: "Originally reserved for royalty, the Hofbrauhaus opened to the public in 1828. Mozart lived next door in 1781 and was a regular. Lenin was a frequent visitor in 1902. The hall was almost completely destroyed in WWII but rebuilt to the original plans because Munchners simply could not imagine their city without it.",
                historicalFacts: [
                    HistoricalFact(year: "1589", title: "The duke's brewery", content: "Duke Wilhelm V founded the Hofbräuhaus as the royal court's private brewery in 1589, mostly to stop his court drinking imported Saxon beer. Public taps came much later.", category: .event),
                    HistoricalFact(year: "1828", title: "Opened to the people", content: "King Ludwig I — populist with a romantic streak — opened the Hofbräuhaus to the public in 1828. The royal court complained, but Bavaria's drinkers cheered.", category: .culture),
                    HistoricalFact(year: "1902", title: "Lenin's Munich beer", content: "From 1900 to 1902 Vladimir Lenin lived in Schwabing and edited the revolutionary newspaper Iskra. He drank regularly at the Hofbräuhaus, where the staff knew him as 'Herr Meyer' — his alias.", category: .famous),
                    HistoricalFact(year: "1958", title: "Rebuilt from the ashes", content: "Allied bombs gutted the hall on 25 April 1944. Reconstruction took fourteen years; the great room reopened in 1958 to the original plans, dark wood ceiling and all.", category: .event)
                ],
                tip: "Sit in the Schwemme for the full experience, or head upstairs to the quieter first-floor hall for conversation. Order a Mass (one liter) of Hofbrau Original and a Schweinshaxe (roasted pork knuckle). Don't be shy about sharing tables — it's tradition, and you'll make friends.",
                durationMinutes: 25,
                iconType: "entertainment",
                walkingNarration: "Walk east from Odeonsplatz through the old town lanes to the Platzl, a cozy square that has been Munich's social hub for centuries. You'll hear the Hofbrauhaus before you see it — the brass band and the clink of steins carry through the streets.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Platzl Square",
                        description: "The charming little Platzl square around the Hofbrauhaus is worth a moment. The building opposite, the Orlando di Lasso House, is named after the Renaissance composer who entertained at the Bavarian court. Street performers often play here in the evenings.",
                        searchQuery: "Platzl Munich",
                        iconSystemName: "music.note"
                    )
                ]
            )
        ],
        isSkeleton: false
    )

    static let beerBreweryTour = TourTemplate(
        id: "munich_beer",
        tourName: "Munich Beer & Brewery Tour",
        tourDescription: "From legendary beer halls to shaded beer gardens, trace five centuries of Munich's brewing heritage and discover why Bavarians take their beer more seriously than almost anything else.",
        category: .munichBeer,
        narrativeThread: "Beer is not just a drink in Munich — it's a constitutional right (almost literally). From the Reinheitsgebot of 1516 to the six great breweries that still define the city, this tour follows the golden thread that runs through Bavarian history, culture, and daily life.",
        guidePersona: GuidePersona(
            name: "Sepp",
            tagline: "Master brewer & storyteller",
            voiceStyle: "jovial, deeply knowledgeable about brewing, loves a good Bavarian anecdote, speaks with hearty warmth",
            greeting: "Servus! I'm Sepp, third-generation brewer and full-time Bierliebhaber. Today I'll take you on a journey through Munich's liquid soul. As we say in Bavaria: Hopfen und Malz, Gott erhalt's — hops and malt, God preserve them! Prost!",
            signoff: "Prost, my friend! You now know more about Munich beer than most Munchners. Remember: in Bavaria, beer is not a luxury, it's a Grundnahrungsmittel — a basic food. Until next time!"
        ),
        stops: [
            TemplateStop(
                name: "Hofbrauhaus",
                searchQuery: "Hofbrauhaus am Platzl Munich",
                description: "Every beer tour must begin at the mother of all beer halls. Founded in 1589 by Duke Wilhelm V because he was tired of paying for expensive imported beer, the Hofbrauhaus has been Munich's iconic drinking establishment for over four centuries. The Schwemme downstairs is a wall of sound, steins, and tradition.",
                historicalNote: "The Hofbrauhaus was originally a brewery, not a pub — the public wasn't allowed in until 1828. The building you see today dates from 1897; the original was nearby. During WWII, the hall was gutted by bombs but the Munchners rebuilt it stone by stone from the original plans, reopening in 1958.",
                historicalFacts: [
                    HistoricalFact(year: "1589", title: "Founded for the court", content: "Duke Wilhelm V founded the Hofbräuhaus in 1589 to brew weissbier for the royal court. Bavarian dukes had grown tired of importing Saxon beer at great cost.", category: .event),
                    HistoricalFact(year: "1897", title: "The Schwemme hall", content: "The current building dates from 1897. The ground-floor Schwemme — the great communal beer hall under arched ceilings — seats roughly 1,300 drinkers, with another 2,000 across the courtyard and upper rooms.", category: .architecture),
                    HistoricalFact(year: nil, title: "Stammtisch culture", content: "Look for tables marked Stammtisch — reserved for regulars who've held them, sometimes by family right, for decades. Sit at one without permission and the regulars will politely (and firmly) explain.", category: .culture)
                ],
                tip: "Order a Mass (one liter) of Hofbrau Original, the classic Helles. If you're brave, try the Hofbrau Dunkel — a rich, malty dark lager that was actually the original style brewed here. The Brezn (pretzels) from the pretzel ladies walking the hall are essential.",
                durationMinutes: 25,
                iconType: "entertainment",
                walkingNarration: nil,
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Hofbrauhaus Stammtisch",
                        description: "Notice the locked stein cabinets along the walls — these belong to Stammgaste, regulars who've earned the right to store their personal Masskrug here. Some families have held the same spot for generations.",
                        searchQuery: "Hofbrauhaus Stammtisch Munich",
                        iconSystemName: "lock.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Augustiner-Keller",
                searchQuery: "Augustiner Keller Arnulfstrasse Munich beer garden",
                description: "If the Hofbrauhaus is where tourists discover Munich beer, the Augustiner-Keller is where Munchners actually drink it. This sprawling beer garden under ancient chestnut trees seats 5,000, and the beer — tapped fresh from wooden barrels — is widely considered the best in the city. Augustiner is Munich's oldest brewery, founded by Augustinian monks in 1328.",
                historicalNote: "Augustiner is the only major Munich brewery still using traditional wooden barrels (Holzfasser) for its Edelstoff lager. The brewery has been in Bavarian hands since the monks sold it in 1803 during secularization. It remains family-owned and fiercely independent — they barely advertise, believing their beer speaks for itself.",
                historicalFacts: [
                    HistoricalFact(year: "1328", title: "Brewing Augustinians", content: "Augustinian monks first brewed beer at this site in 1328, making Augustiner Munich's oldest still-operating brewery. The monks supplied beer to lay people on feast days only.", category: .event),
                    HistoricalFact(year: "1803", title: "Secularization", content: "When Bavaria secularized monastic property in 1803, the brewery passed to private hands. The Wagner family bought it in 1829 and the Inselkammer family took it over in 1856 — Augustiner has been Bavarian-family-owned ever since.", category: .culture),
                    HistoricalFact(year: nil, title: "Wooden barrels still", content: "Augustiner remains the only major Munich brewery still serving its Edelstoff and Helles from wooden Holzfasser barrels at its core taverns and beer gardens. The wood breathes during transport and gives the beer its softer mouthfeel.", category: .general)
                ],
                tip: "Head to the Selbstbedienung (self-service) area, grab a Mass of Augustiner Edelstoff vom Holzfass (from the wooden barrel), and find a spot under the chestnuts. Bringing your own food is not only allowed but encouraged — that's the Bavarian beer garden tradition.",
                durationMinutes: 25,
                iconType: "entertainment",
                walkingNarration: "Head west from the Hofbrauhaus through the city center toward Arnulfstrasse near the Hauptbahnhof. The walk takes you from tourist Munich to everyday Munich — and the beer gets better with every step, I promise.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Augustiner Brewery Building",
                        description: "The historic Augustiner brewery building on Landsberger Strasse, though no longer in active use for brewing, still bears the old signage and architectural details of a 19th-century Bavarian brewery. The actual brewery moved to a larger site but this building remains a beloved landmark.",
                        searchQuery: "Augustiner Brauerei Landsberger Strasse Munich"
                    )
                ]
            ),
            TemplateStop(
                name: "Viktualienmarkt Beer Garden",
                searchQuery: "Viktualienmarkt Biergarten Munich",
                description: "Tucked in the heart of Munich's famous food market, this unique beer garden rotates its taps among all six major Munich breweries — Augustiner, Hofbrau, Lowenbrau, Paulaner, Spaten, and Hacker-Pschorr — so you never know which one you'll get. Surrounded by the market's food stalls, it's the perfect spot to pair a Mass with local delicacies.",
                historicalNote: "The six-brewery rotation system was established to ensure fairness and give all breweries equal access to this prime location. It's a very Bavarian solution — democratic, practical, and beer-focused. The Reinheitsgebot of 1516, the world's oldest food regulation still in use, was enacted by Duke Wilhelm IV right here in Bavaria. It decreed that beer could only contain water, barley, and hops.",
                historicalFacts: [
                    HistoricalFact(year: "1516", title: "The Reinheitsgebot", content: "On 23 April 1516 in Ingolstadt, Duke Wilhelm IV decreed that Bavarian beer could only contain water, barley, and hops. The Reinheitsgebot is still the world's oldest food regulation in continuous use.", category: .event),
                    HistoricalFact(year: nil, title: "The six-brewery rotation", content: "Munich's six big breweries — Augustiner, Hofbräu, Löwenbräu, Paulaner, Spaten, Hacker-Pschorr — rotate as the official supplier of the Viktualienmarkt beer garden week by week. A very Bavarian compromise.", category: .culture),
                    HistoricalFact(year: nil, title: "Bring your own food", content: "Bavarian beer-garden law lets you bring your own food, since traditionally only beer was sold. Pull up a bench, unpack bread and cheese — and buy your Mass at the bar.", category: .culture)
                ],
                tip: "Check the flag at the beer garden entrance to see which brewery is currently pouring. Buy your beer at the counter, then grab a Steckerlfisch (grilled fish on a stick) or an Obatzda (spiced cheese spread with a Brezn) from the surrounding stalls. Gemutlichkeit at its finest.",
                durationMinutes: 20,
                iconType: "entertainment",
                walkingNarration: "Walk back east toward the Viktualienmarkt. Sepp's rule of beer gardens: the best ones have chestnut trees for shade, gravel underfoot, and no background music — just conversation and clinking steins. The Viktualienmarkt checks every box.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Maypole (Maibaum)",
                        description: "The tall maypole in the beer garden is decorated with symbols of Munich's trades and guilds. Maypole traditions run deep in Bavaria — villages still compete to steal each other's poles, which must then be ransomed back with beer.",
                        searchQuery: "Maibaum Viktualienmarkt Munich",
                        iconSystemName: "tree.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Chinesischer Turm (English Garden)",
                searchQuery: "Chinesischer Turm Biergarten English Garden Munich",
                description: "Munich's second-largest beer garden surrounds the iconic five-story Chinese Tower in the heart of the English Garden. With 7,000 seats, a brass band playing from the tower's first floor on summer weekends, and ancient chestnut trees providing dappled shade, this is the quintessential Munich beer garden experience.",
                historicalNote: "The English Garden was created in 1789 by Sir Benjamin Thompson (Count Rumford), an American-born scientist and statesman serving the Bavarian court. It was one of the world's first public parks. The Chinese Tower, built in 1790, was inspired by the pagoda at Kew Gardens in London. It's burned down and been rebuilt twice.",
                historicalFacts: [
                    HistoricalFact(year: "1789", title: "An American at the Bavarian court", content: "Benjamin Thompson — American-born physicist, made Count Rumford by Elector Karl Theodor — convinced the Elector to convert royal hunting grounds into a public park in 1789. It was one of the first public parks in continental Europe.", category: .famous),
                    HistoricalFact(year: "1790", title: "A pagoda for Bavaria", content: "The Chinese Tower, built in 1790, was modelled on the pagoda at Kew Gardens in London. It has burned down twice — in 1944 and earlier — and been rebuilt to the same plans both times.", category: .architecture),
                    HistoricalFact(year: nil, title: "Larger than Central Park", content: "At about 375 hectares, the English Garden is one of the largest urban parks in the world — larger than Central Park or Hyde Park. The Eisbach river runs the length of it.", category: .nature)
                ],
                tip: "The self-service area is cheaper and more authentic than the seated restaurant section. Grab a Radler (beer mixed with lemon soda) if you want something lighter — Bavarians invented it in the 1920s when a brewer ran low on beer and stretched it with lemonade for thirsty cyclists.",
                durationMinutes: 25,
                iconType: "park",
                walkingNarration: "Now we head north to the English Garden, Munich's green lung and home to some of its finest beer gardens. The park is larger than Central Park in New York — Munchners are very proud of that fact.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "English Garden Meadows",
                        description: "The wide-open meadows around the Chinese Tower fill with sunbathers, frisbee players, and picnickers on warm days. Bavarians embrace Freikdrperkultur (free body culture) — don't be surprised to see nude sunbathing. It's completely normal here.",
                        searchQuery: "English Garden Munich Schonfeld Wiese",
                        iconSystemName: "sun.max.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Paulaner Brauhaus",
                searchQuery: "Paulaner Brauhaus Kapuzinerplatz Munich",
                description: "Paulaner's flagship brewpub combines a working microbrewery with a traditional Bavarian restaurant. Watch the copper kettles gleaming through glass walls while you taste their unfiltered house lager, brewed right on site. The Paulaner monks who founded the brewery in 1634 would approve — they brewed strong beer to sustain themselves through Lenten fasting.",
                historicalNote: "Paulaner monks invented Salvator, the original Doppelbock, as 'liquid bread' for Lent. The name Salvator became so famous that virtually all Doppelbock beers now end in '-ator' in tribute. Every spring, Munich celebrates Starkbierzeit (strong beer season) — essentially a second Oktoberfest but for locals, centered on these powerful monastery brews.",
                historicalFacts: [
                    HistoricalFact(year: "1634", title: "Liquid bread for Lent", content: "Paulaner monks of the Order of Saint Francis of Paola began brewing a strong, calorie-rich Doppelbock in 1634 as 'liquid bread' to sustain them through Lenten fasting. The Pope had ruled the brew was a drink, not a food — so it was permitted.", category: .event),
                    HistoricalFact(year: nil, title: "Why Doppelbocks end in -ator", content: "Paulaner's strong beer was called Salvator. It became so famous that other Bavarian brewers copied not just the recipe but the suffix. Today nearly every German Doppelbock ends in -ator: Triumphator, Optimator, Maximator, Celebrator.", category: .culture),
                    HistoricalFact(year: nil, title: "Starkbierzeit, the local Oktoberfest", content: "Two weeks before Easter, Munich locals gather at the Nockherberg for Starkbierzeit — a festival of monastic strong beers. It's the annual moment when politicians are publicly mocked from the pulpit by a comedian-monk during the Singspiel.", category: .culture)
                ],
                tip: "Order the Paulaner Zwickl — their unfiltered house lager brewed mere meters from your table. Pair it with a plate of Schweinshaxe or Obatzda. Ask about the Salvator if visiting during Lent (February-March) — it's a Munich institution.",
                durationMinutes: 25,
                iconType: "restaurant",
                walkingNarration: "Head south from the English Garden toward the river. We're going to taste beer where it's brewed, which any self-respecting Bavarian will tell you is the only proper way to drink it.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Nockherberg Paulaner",
                        description: "Nearby on the Nockherberg hill is Paulaner's historic brewery and event hall, where the annual Starkbierfest kicks off strong beer season each spring. Politicians attend the Derblecken ceremony where they're roasted by comedians — a beloved Munich tradition.",
                        searchQuery: "Nockherberg Paulaner Munich Starkbierfest",
                        iconSystemName: "building.2.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Augustiner Stammhaus",
                searchQuery: "Augustiner Stammhaus Neuhauser Strasse Munich",
                description: "We end where Munich's brewing story began — at the Augustiner Stammhaus, the original home of the city's oldest and most beloved brewery. This traditional restaurant in the pedestrian zone serves Augustiner beer in a setting that hasn't changed much in a century. The dark wood paneling, vaulted ceilings, and unhurried atmosphere make it the perfect place for a final toast.",
                historicalNote: "The Stammhaus (ancestral house) occupies the site where Augustinian monks first brewed beer in 1328. When the monastery was dissolved in 1803, the brewery passed to private hands but the Bavarian brewing tradition continued unbroken. Augustiner remains the only Munich brewery never to have been bought by a corporation.",
                historicalFacts: [
                    HistoricalFact(year: "1328", title: "Munich's oldest brewery, on this very block", content: "Augustinian monks first brewed beer on this site in 1328. The Stammhaus, the 'ancestral house,' has stood here in some form ever since.", category: .event),
                    HistoricalFact(year: nil, title: "Never sold to a corporation", content: "Augustiner is the only one of Munich's six big breweries never to have been absorbed into a multinational. It's still owned by the Edith Haberland Wagner Trust and the Inselkammer family.", category: .culture),
                    HistoricalFact(year: nil, title: "No advertising, ever", content: "Augustiner is famously secretive about marketing — there's no national advertising campaign and very little branded merchandise. Munchners say the company believes the beer should sell itself.", category: .general)
                ],
                tip: "Order the Augustiner Helles — many Munchners consider it the finest beer in the world, and they'll argue about it passionately. Try it alongside a Wurstsalat (sliced sausage salad with vinegar and onions) for the most Bavarian way to end a beer tour. Zum Wohl!",
                durationMinutes: 25,
                iconType: "restaurant",
                walkingNarration: "We circle back to the city center for our grand finale. The walk from Paulaner to the Stammhaus takes you along the Isar River and back into the old town — a perfect way to build up one last proper thirst.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Neuhauser Strasse Pedestrian Zone",
                        description: "Munich's main pedestrian shopping street has been car-free since 1972, when the city built its U-Bahn for the Olympics. Street musicians, pretzel vendors, and the constant flow of Munchners make it one of Europe's liveliest promenades.",
                        searchQuery: "Neuhauser Strasse pedestrian zone Munich",
                        iconSystemName: "figure.walk"
                    )
                ]
            )
        ],
        isSkeleton: false
    )

    static let bavarianFoodTrail = TourTemplate(
        id: "munich_food",
        tourName: "Bavarian Food Trail: A Munich Feast",
        tourDescription: "Taste your way through Munich's culinary soul — from the legendary Weisswurst breakfast ritual to pillowy Knodel, artisan delicatessens, and the coffee houses where Bavaria's sweet tooth runs wild.",
        category: .munichFood,
        narrativeThread: "Bavarian cuisine is comfort food elevated to an art form. Every dish tells a story — of monks who brewed and baked, of farmers who fed a kingdom, and of grandmothers who refused to let a single recipe be forgotten. This tour follows those recipes from market stall to table.",
        guidePersona: GuidePersona(
            name: "Anni",
            tagline: "Third-generation Bavarian cook",
            voiceStyle: "motherly warmth, opinionated about tradition, shares family recipes and kitchen secrets, firm about what's authentic",
            greeting: "Servus, Schatzl! I'm Anni, and I learned to cook standing on a stool in my Oma's kitchen. Today I'll feed you the real Munich — no tourist menus, no shortcuts. An Guadn!",
            signoff: "I hope your belly is full and your heart is happy — that's the whole point of Bavarian cooking. Come back hungry, and I'll show you what we eat in winter. Pfiat Eich!"
        ),
        stops: [
            TemplateStop(
                name: "Viktualienmarkt",
                searchQuery: "Viktualienmarkt Munich food market",
                description: "Munich's culinary heart beats at this open-air market, where over 140 stalls offer the finest Bavarian produce. From aged Bergkase (mountain cheese) and hand-made Weisswurst to smoked trout from Alpine lakes and fragrant bundles of fresh herbs, this is where Munich's best chefs shop — and where our food story begins.",
                historicalNote: "The market has operated on this site since 1807, when it outgrew the Marienplatz. Each stall family often holds a hereditary license passed down through generations. Losing your Viktualienmarkt stall is considered a greater tragedy than losing your apartment.",
                historicalFacts: [
                    HistoricalFact(year: "1807", title: "Outgrew the main square", content: "King Max Joseph moved the food market off Marienplatz in 1807. The new site grew from a few dozen stalls into the 22,000 square metres of food halls and beer garden you see today.", category: .event),
                    HistoricalFact(year: nil, title: "Hereditary licences", content: "Many stalls are run by families holding hereditary licences. The market authority has a long waiting list and turnover is rare; some families have been here for six generations.", category: .culture),
                    HistoricalFact(year: nil, title: "Prices reflect rent, not greed", content: "Stallholders pay rent to the city, and the city subsidises a handful of small stalls so artisanal producers can afford the central spot. That's why a jar of small-batch preserves here costs three times what it does in a supermarket — and tastes ten times better.", category: .general)
                ],
                tip: "Start at the Honig-Mair stall for a taste of Alpine honey, then visit the Turkenhof cheese stand for samples of aged Allgauer Bergkase. Don't be shy about asking to taste — the vendors expect it and take pride in their products.",
                durationMinutes: 25,
                iconType: "shopping",
                walkingNarration: nil,
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Spice Stalls",
                        description: "The spice and herb stalls near the south end sell Bavarian specialties like Brotgewurz (bread spice mix of caraway, fennel, and coriander) and smoked salt from the Alps. These make perfect edible souvenirs and weigh almost nothing.",
                        searchQuery: "Viktualienmarkt spice stalls Munich",
                        iconSystemName: "leaf.fill"
                    ),
                    TemplateDiscoveryPoint(
                        name: "Wild Game Stall",
                        description: "Look for the Wildhandlung (game butcher), one of the few remaining in Munich. They sell venison, wild boar, and hare sourced from Bavarian forests — ingredients that have been central to the local diet for centuries.",
                        searchQuery: "Viktualienmarkt Wildhandlung Munich"
                    )
                ]
            ),
            TemplateStop(
                name: "Dallmayr Delicatessen",
                searchQuery: "Dallmayr Delikatessenhaus Dienerstrasse Munich",
                description: "Munich's most famous delicatessen has been a temple of fine food since 1700. The ground floor is a sensory wonderland: towers of handmade chocolates, counters of French cheese alongside Bavarian specialties, exotic fruits, and their legendary coffee — roasted in-house to a closely guarded recipe. Dallmayr supplies delicacies to royalty across Europe.",
                historicalNote: "The Dallmayr family began as a spice trader in the 17th century. By the 19th century, they were official purveyors to the Bavarian royal court. Their Prodomo coffee blend, created in the 1930s, became Germany's best-known coffee brand. The Munich flagship store remains the crown jewel.",
                historicalFacts: [
                    HistoricalFact(year: "1700", title: "From spices to royalty", content: "The Dallmayr business began around 1700 as a spice trader near Marienplatz. By the early 1800s the firm held a Bavarian royal warrant — Hofkonditor — supplying coffee, tea, and exotics to the Wittelsbach court.", category: .general),
                    HistoricalFact(year: "1930", title: "Prodomo, decaf done right", content: "Dallmayr's Prodomo coffee, launched in the 1930s, was an early caffeine-friendly blend that the brand still markets today. It made Dallmayr a national name across Germany.", category: .culture),
                    HistoricalFact(year: nil, title: "Marble halls of food", content: "The flagship store's blue marble walls, painted ceiling, and gilded lettering survived World War II. Walk in, look up, and you'll see how a 19th-century Bavarian luxury merchant imagined the future of food retail.", category: .architecture)
                ],
                tip: "Head straight to the coffee counter and order a cup of their house roast — it's arguably the best coffee in Munich. The prepared foods counter offers exquisite take-away salads and sandwiches if you want a gourmet picnic. Upstairs, the restaurant serves refined Bavarian cuisine.",
                durationMinutes: 20,
                iconType: "shopping",
                walkingNarration: "Walk north from the Viktualienmarkt toward the Residenz. Dienerstrasse is a quiet lane that hides one of Europe's grandest delicatessens behind an unassuming entrance. The window displays alone are worth the detour.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Dallmayr Chocolate Counter",
                        description: "The in-house chocolatier creates seasonal pralines and truffles that rival any Swiss or Belgian confection. The Bavarian cream truffle and the marzipan varieties are local favourites. Beautifully boxed sets make the perfect Munich gift.",
                        searchQuery: "Dallmayr chocolate Munich",
                        iconSystemName: "gift.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Schneider Brauhaus",
                searchQuery: "Schneider Brauhaus Tal Munich Weisswurst",
                description: "This is where the Weisswurst ritual comes alive. Schneider Brauhaus, home of the famous Schneider Weisse wheat beer, serves Munich's most celebrated Weisswurst breakfast. The plump white veal sausages arrive in a bowl of hot water, accompanied by sweet mustard, a fresh Brezn, and a tall glass of Weissbier. Learning to properly zuzeln (suck the sausage from its skin) is a Bavarian rite of passage.",
                historicalNote: "Weisswurst was allegedly invented in Munich on February 22, 1857, by a butcher named Sepp Moser who ran out of sheep casings and used pork casings instead, then boiled rather than fried the sausages to prevent them from bursting. Tradition insists Weisswurst must be eaten before noon — before the church bells ring twelve, as they say — because they were made fresh each morning without preservatives.",
                historicalFacts: [
                    HistoricalFact(year: "1857", title: "An accident at carnival", content: "Munich folklore credits butcher Sepp Moser at the Gasthaus Zum Ewigen Licht with inventing the Weisswurst on Rosenmontag, 22 February 1857 — when he ran out of sheep casings and used pork instead, simmering rather than frying so the sausages wouldn't burst.", category: .legend),
                    HistoricalFact(year: nil, title: "Before the bells of noon", content: "Tradition says a Weisswurst must never hear the chime of midday. The unsmoked, unpreserved sausages were made fresh each morning, and any leftover at noon went to the household animals.", category: .culture),
                    HistoricalFact(year: nil, title: "Zuzeln, not zerschneiden", content: "The proper way to eat one is zuzeln — sucking the sausage out of its casing without a knife. Cutting it like a Frankfurter will mark you as a foreigner more clearly than your accent.", category: .culture)
                ],
                tip: "Order the Weisswurstfruhstuck (white sausage breakfast) even if it's not morning — Schneider serves it all day, and Anni won't judge. Use the sweet mustard, never the spicy Senf. Pair with a Schneider Weisse Original — the wheat beer and the sausage were made for each other.",
                durationMinutes: 25,
                iconType: "restaurant",
                walkingNarration: "Head down the Tal, one of Munich's oldest streets, toward the Isartor. Schneider Brauhaus has occupied this building since 1872, and the wafting scent of fresh Brezn and simmering sausages guides you like a Bavarian compass.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Isartor Gate",
                        description: "At the end of the Tal stands the Isartor, one of Munich's three remaining medieval gates. The fresco on the tower depicts Emperor Ludwig the Bavarian's triumphant return after the Battle of Ampfing in 1322. Inside, a small museum honors comedian Karl Valentin.",
                        searchQuery: "Isartor Munich gate",
                        iconSystemName: "building.columns.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Cafe Luitpold",
                searchQuery: "Cafe Luitpold Brienner Strasse Munich",
                description: "Munich's grandest Kaffeehaus, opened in 1888 and named after Prince Regent Luitpold, has been the city's living room for the well-heeled and the artistic alike. The palm-court interior, restored to its original Belle Epoque splendor, is the perfect setting for Bavaria's extraordinary cake tradition. The display counter is a cathedral of cream, chocolate, and pastry.",
                historicalNote: "Cafe Luitpold was Munich's first establishment to install electric lighting, causing a sensation in 1888. Thomas Mann, Richard Strauss, and Kandinsky were regulars. The cafe was destroyed in WWII but lovingly reconstructed and has been a Schwabinger institution ever since.",
                historicalFacts: [
                    HistoricalFact(year: "1888", title: "Munich's first electric café", content: "Café Luitpold was the first café in Munich to install electric lighting in 1888. The lit-up Sunday afternoons drew crowds who came simply to stare at the bulbs.", category: .event),
                    HistoricalFact(year: nil, title: "Where the Schwabing bohemians met", content: "Thomas Mann, Richard Strauss, Wassily Kandinsky and Franz Marc all kept tables here. Mann set scenes from Buddenbrooks and Felix Krull in cafés clearly modelled on Luitpold.", category: .famous),
                    HistoricalFact(year: "1944", title: "Reduced to rubble, rebuilt", content: "Allied bombs destroyed the original building in 1944. The current café reopened in 1962 with a more modern interior, but the marble counters and crystal chandeliers are reproductions of the originals.", category: .event)
                ],
                tip: "Order a slice of Prinzregententorte — Munich's signature cake, with seven thin layers of sponge and chocolate buttercream representing the seven Bavarian districts. Pair it with a Melange (Viennese-style milky coffee). The cake is rich, so share if you still have stops to go.",
                durationMinutes: 20,
                iconType: "restaurant",
                walkingNarration: "Walk west toward Brienner Strasse, one of Munich's four royal boulevards. The shift from the old town's medieval bustle to the neoclassical elegance of this quarter is palpable. Cafe Luitpold sits right at the heart of it.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Luitpold Block Courtyard",
                        description: "Step through the courtyard behind Cafe Luitpold to discover a hidden cluster of artisan shops, a chocolate maker, and a peaceful garden terrace. This Hinterhof (back courtyard) is a Munich secret that most visitors miss.",
                        searchQuery: "Luitpoldblock Munich courtyard",
                        iconSystemName: "camera.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Schmalznudel - Cafe Frischhut",
                searchQuery: "Cafe Frischhut Schmalznudel Prälat-Zistl-Strasse Munich",
                description: "This no-frills bakery near the Viktualienmarkt has been frying its legendary Schmalznudel since 1973 — puffy rectangles of yeast dough, fried golden in lard, and dusted with sugar. Crisp outside, impossibly airy inside, and best eaten standing at the counter while they're still warm. There's usually a queue, and it's always worth it.",
                historicalNote: "Schmalzgebackenes (lard-fried pastries) have been a Bavarian tradition since medieval times, originally eaten during Fasching (carnival season) before Lent. Cafe Frischhut is one of the last bakeries in Munich still frying them fresh all day in the traditional way.",
                historicalFacts: [
                    HistoricalFact(year: nil, title: "A pre-Lenten tradition", content: "Schmalzgebackenes — pastries fried in lard — were originally a Fasching (carnival) treat made to use up household fat before Lent. The tradition stuck, and now Munchners eat them all year.", category: .culture),
                    HistoricalFact(year: nil, title: "The Auszogene's wide centre", content: "The signature pastry, the Auszogene, is hand-stretched until the centre is almost paper-thin. It puffs around a thicker doughnut-like rim when fried — light in the middle, satisfying at the edges.", category: .general)
                ],
                tip: "Order a Schmalznudel and an Ausgezogene (a stretched, thinner version — crispier and even more addictive). Eat them immediately — they lose their magic within minutes. A simple Kaffee is the only accompaniment you need.",
                durationMinutes: 15,
                iconType: "restaurant",
                walkingNarration: "Double back toward the Viktualienmarkt area. You'll know you're close when you catch the scent of frying dough and see the queue of locals snaking out the door of a tiny, unassuming bakery. That queue is your destination.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Heiliggeistkirche",
                        description: "The Gothic church directly next to Cafe Frischhut dates to the 14th century and features a beautifully restored baroque interior. The contrast between the sacred calm inside and the sugary chaos of the bakery next door is pure Munich.",
                        searchQuery: "Heiliggeistkirche Munich",
                        iconSystemName: "cross.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Wirtshaus in der Au",
                searchQuery: "Wirtshaus in der Au Lilienstrasse Munich Knodel",
                description: "Munich's beloved Knodel temple — a cozy Wirtshaus (tavern) in the Au district famous for its extraordinary potato and bread dumplings. The Knodel here are handmade to recipes that haven't changed in generations: pillowy, buttery, and the size of your fist. The annual Knodelfest draws thousands of dumpling devotees from across Bavaria.",
                historicalNote: "Knodel (dumplings) are the cornerstone of Bavarian cuisine, dating back to at least the 16th century. They evolved as a way to use stale bread (Semmelknodel) or stretch potatoes (Kartoffelknodel) into filling, satisfying meals. The Au neighborhood was historically a working-class district where hearty, affordable food was essential.",
                historicalFacts: [
                    HistoricalFact(year: nil, title: "Don't waste the bread", content: "Bavarian Knödel evolved as a way not to waste hard bread or surplus potatoes. Semmelknödel uses day-old bread rolls; Kartoffelknödel uses cooked potatoes; Brezenknödel uses stale pretzels. Nothing was thrown away.", category: .culture),
                    HistoricalFact(year: nil, title: "Au, the workers' quarter", content: "The Au district sits low along the Isar and was for centuries a working-class neighbourhood prone to flooding. Cheap rents drew tradesmen, washerwomen, and small breweries — and the hearty cuisine of the Wirtshäuser still reflects that.", category: .general),
                    HistoricalFact(year: nil, title: "Mariahilfkirche, Au's anchor", content: "The Mariahilfkirche just down the street, completed in 1839, was one of Munich's first neo-Gothic churches. Its tall spire is the visual anchor of the Au.", category: .architecture)
                ],
                tip: "Order the Knodelvariation — a sampler plate of different dumpling styles, from classic Semmelknodel with mushroom cream sauce to Spinatknodel with browned butter and Parmesan. The Kaiserschmarrn (shredded pancake with plum sauce) for dessert is magnificent. Book ahead — this place fills up fast.",
                durationMinutes: 30,
                iconType: "restaurant",
                walkingNarration: "Cross the Isar River to reach the Au, one of Munich's most characterful neighborhoods. The Au was once a separate village of washerwomen and craftsmen. Today it retains that intimate, village-like feel, and the Wirtshaus in der Au is its crown jewel.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Mariahilfkirche",
                        description: "The twin-towered Mariahilfkirche in the Au is one of Munich's most striking churches, dominating the neighborhood skyline. The Auer Dult, Munich's oldest and most charming traditional market, takes place on the square in front three times a year.",
                        searchQuery: "Mariahilfkirche Au Munich Auer Dult",
                        iconSystemName: "building.columns.fill"
                    )
                ]
            )
        ],
        isSkeleton: false
    )

    // MARK: - Skeleton Templates (Claude enriches at runtime)

    static let englishGardenWalk = TourTemplate(
        id: "munich_english_garden",
        tourName: "English Garden Walk: Nature Meets City",
        tourDescription: "Stroll through one of the world's largest urban parks — from river surfers and Greek temples to hidden lakes and legendary beer gardens, discovering where Munchners escape to breathe.",
        category: .munichEnglishGarden,
        narrativeThread: "The English Garden is Munich's green soul — a vast, wild park where surfers ride a river wave, sunbathers lounge on meadows, and centuries-old beer gardens buzz beneath chestnut canopies. This walk reveals how nature and city life intertwine in Munich.",
        guidePersona: GuidePersona(
            name: "Lena",
            tagline: "Outdoor enthusiast & Munich native",
            voiceStyle: "relaxed, enthusiastic, genuinely loves nature, peppers in local Munich slang",
            greeting: "Servus! I'm Lena, born and raised right here by the Isar. The English Garden is basically my backyard — I've been running, swimming, and drinking Radler here since I was a teenager. Let me show you my favourite Fleckerl in the park!",
            signoff: "I hope the park worked its magic on you — it always does on me. Next time, bring a swimsuit and a book, and lose a whole day here. Mach's gut!"
        ),
        stops: [
            TemplateStop(
                name: "Eisbach Surfer Wave",
                searchQuery: "Eisbach wave surfers English Garden Munich",
                description: "One of the most unexpected sights in any European city: skilled surfers riding a permanent standing wave on the Eisbach river at the park's southern entrance. The wave has been surfed since the 1970s, and watching the surfers peel in and out is mesmerizing. There's always a crowd of onlookers leaning over the bridge.",
                historicalNote: "Surfing here was technically illegal until 2010, when the city finally legalized it after decades of Munchners doing it anyway. The Eisbach wave is considered one of the best river waves in the world.",
                historicalFacts: [
                    HistoricalFact(year: nil, title: "An accidental wave", content: "The Eisbach standing wave was an accident. When engineers laid concrete blocks on the river bed in the 1970s to slow the current, they shaped a perfect standing wave that surfers discovered within months.", category: .nature),
                    HistoricalFact(year: "2010", title: "Legalised at last", content: "Surfing here was technically illegal for decades. The city legalised it in 2010 after years of Munchners doing it anyway and crowds gathering on the bridge to watch.", category: .event),
                    HistoricalFact(year: nil, title: "Year-round, ice or no ice", content: "The wave never stops, so neither do the surfers. In winter, you'll find them in heavy wetsuits cracking ice off the riverbank between rides.", category: .culture)
                ],
                tip: "The bridge on Prinzregentenstrasse offers the best viewing spot. Mornings are quieter and the surfers tend to be more experienced. The water is ice-cold year-round — fed by Alpine snowmelt.",
                durationMinutes: 15,
                iconType: "viewpoint",
                walkingNarration: nil,
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Haus der Kunst",
                        description: "The imposing building overlooking the Eisbach is the Haus der Kunst, now one of Munich's premier contemporary art museums. Originally built by the Nazis in 1937, it has been powerfully reclaimed as a space for the avant-garde art they sought to destroy.",
                        searchQuery: "Haus der Kunst Munich museum"
                    )
                ]
            ),
            TemplateStop(
                name: "Monopteros Temple",
                searchQuery: "Monopteros English Garden Munich temple",
                description: "This small Greek-style temple on a hilltop offers one of the best panoramic views in Munich — the city skyline with the Alps behind it on clear days. Built in 1836 by Leo von Klenze, the Monopteros is a beloved Munich landmark and a favourite picnic spot for locals.",
                historicalNote: "King Ludwig I commissioned the Monopteros as part of his vision to transform Munich into the 'Athens on the Isar.' The neoclassical temple sits on an artificial hill made from rubble from demolished city buildings.",
                historicalFacts: [
                    HistoricalFact(year: "1837", title: "Athens on the Isar", content: "Ludwig I commissioned the Monopteros in 1832, completed in 1837, as part of his project to make Munich an 'Athens on the Isar.' The little Greek temple was built on an artificial hill made of rubble from demolished old city buildings.", category: .famous),
                    HistoricalFact(year: nil, title: "Klenze's Romantic touch", content: "The architect was Leo von Klenze, who also designed the Königsplatz and the Walhalla near Regensburg. The temple's twelve Ionic columns echo the Tholos at Delphi.", category: .architecture),
                    HistoricalFact(year: nil, title: "Best skyline in Munich", content: "Climb the hill at sunset for one of the best free views in Munich — the Frauenkirche's twin towers framed against the Alps when the air is clear.", category: .general)
                ],
                tip: "Climb up in the late afternoon for golden light on the city skyline. On clear days, the Alps are visible beyond the church towers. It's a popular sunset spot — bring a blanket and something to drink.",
                durationMinutes: 15,
                iconType: "viewpoint",
                walkingNarration: "Walk north along the Eisbach stream into the park. The paths meander through open meadows where Munchners sunbathe, play football, and practice yoga. After about ten minutes, you'll see a small hill with a classical temple on top — that's your next stop.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Schonfeld Meadow",
                        description: "The broad meadow below the Monopteros is the park's social hub in summer — joggers, musicians, picnickers, and sunbathers share the space in a uniquely relaxed Munich atmosphere. You may encounter nudity; FKK (free body culture) is a long Bavarian tradition here.",
                        searchQuery: "Schonfeld Wiese English Garden Munich",
                        iconSystemName: "sun.max.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Chinesischer Turm (Chinese Tower)",
                searchQuery: "Chinesischer Turm Beer Garden English Garden Munich",
                description: "The five-story wooden pagoda, originally built in 1790, is the centerpiece of Munich's second-largest beer garden. Seating 7,000 under spreading chestnut trees, with a brass band playing from the tower on summer weekends, it's everything a Bavarian beer garden should be.",
                historicalNote: nil,
                tip: "Self-service is the way to go here. Grab a Mass of whatever's on tap and a Halbes Hendl (half roast chicken). If you're with kids, there's a charming antique carousel right next to the beer garden.",
                durationMinutes: 25,
                iconType: "entertainment",
                walkingNarration: "Continue north through the park. The sound of a brass band drifting through the trees will tell you you're getting close. The Chinese Tower appears through gaps in the canopy like a storybook illustration.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Carousel at Chinese Tower",
                        description: "A beautifully restored vintage carousel with hand-painted horses and carriages operates right beside the beer garden. It's been delighting Munich families for generations and is a charming photo opportunity.",
                        searchQuery: "Karussell Chinesischer Turm Munich",
                        iconSystemName: "star.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Kleinhesseloher See",
                searchQuery: "Kleinhesseloher See English Garden Munich lake",
                description: "This tranquil lake in the park's center is a world away from city noise. Pedal boats drift across the water, ducks paddle between the small islands, and the surrounding weeping willows create a scene worthy of a Romantic painting. On one shore, the elegant Seehaus restaurant peers over the water.",
                historicalNote: nil,
                tip: "Rent a pedal boat for a half-hour on the lake — it's surprisingly peaceful and gives you a completely different perspective of the park. The southern shore is quietest for a lakeside rest.",
                durationMinutes: 15,
                iconType: "park",
                walkingNarration: "Walk north through the wilder, less manicured part of the park. The paths narrow, the trees thicken, and before long you emerge at the shore of a lovely lake. This is where Munchners come when they want proper tranquility.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Park Wildlife",
                        description: "Keep your eyes open for the park's wildlife — grey herons fish along the lake shore, woodpeckers hammer in the older trees, and if you're very lucky, you might spot a fox at dawn or dusk. The English Garden is a genuine urban ecosystem.",
                        searchQuery: "Kleinhesseloher See wildlife English Garden Munich",
                        iconSystemName: "bird.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Amphitheater",
                searchQuery: "Amphitheater English Garden Munich",
                description: "Tucked away in the northern reaches of the park, this open-air amphitheater hosts free concerts, theater performances, and film screenings throughout the summer. Even when empty, the grassy bowl with its simple wooden stage has a magical, hidden-glade quality.",
                historicalNote: nil,
                tip: "Check the program for free summer events — Shakespeare in the park, jazz concerts, and family theater happen here regularly. Even without a show, it's a beautifully peaceful spot to sit and read.",
                durationMinutes: 10,
                iconType: "entertainment",
                walkingNarration: "Continue north past the lake along quieter paths. The park feels increasingly wild here — fewer people, taller grass, older trees. The amphitheater sits in a gentle depression, easy to miss if you don't know it's there.",
                discoveryPoints: []
            ),
            TemplateStop(
                name: "Seehaus Beer Garden",
                searchQuery: "Seehaus im Englischen Garten Munich",
                description: "Our final stop is this elegant lakeside beer garden and restaurant on the shore of the Kleinhesseloher See. It's a favourite of locals who prefer a slightly more refined beer garden experience — the lake views, the willow trees, and the sunset make it genuinely romantic.",
                historicalNote: nil,
                tip: "Grab a table on the lakeside terrace if you can. The Seehaus serves excellent Bavarian classics alongside lighter, more modern dishes. A Helles and a Steckerlfisch (grilled fish on a stick) with the lake glimmering in front of you is pure Munich bliss.",
                durationMinutes: 25,
                iconType: "restaurant",
                walkingNarration: "Loop back south toward the lake for your reward — a cold beer with a view. The path hugs the water's edge, and in the evening light the lake turns gold. You've earned this, believe me.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Seehaus Sunset View",
                        description: "The west-facing terrace at the Seehaus catches some of Munich's most beautiful sunsets, especially in summer when the light lingers past nine. The lake reflects the sky in watercolors.",
                        searchQuery: "Seehaus Englischer Garten sunset Munich",
                        iconSystemName: "sunset.fill"
                    )
                ]
            )
        ],
        isSkeleton: true
    )

    static let royalMunich = TourTemplate(
        id: "munich_royal",
        tourName: "Royal Munich: Palaces & Power",
        tourDescription: "Trace the 700-year reign of the Wittelsbach dynasty through their palaces, gardens, churches, and theaters — the royal family that turned a small market town into a European capital of art and culture.",
        category: .munichRoyal,
        narrativeThread: "For over seven centuries, the Wittelsbach dynasty shaped Munich from a muddy river crossing into one of Europe's great cultural capitals. From their fortress beginnings at the Alter Hof to the opulent Residenz, every stone tells the story of ambition, art, and occasionally magnificent madness.",
        guidePersona: GuidePersona(
            name: "Ludwig",
            tagline: "Named after the kings & proud of it",
            voiceStyle: "dignified but never stuffy, deeply passionate about the Wittelsbachs, treats royal history like a family saga",
            greeting: "Gruss Gott! I'm Ludwig — yes, named after the famous kings, and no, I never get tired of it. Today I'll introduce you to the family that built this city. Seven hundred years of royalty, and I promise you, it's never boring.",
            signoff: "The Wittelsbachs may be gone, but their city endures — more beautiful than they could have dreamed. Auf Wiedersehen, and long live Bavaria!"
        ),
        stops: [
            TemplateStop(
                name: "Residenz Palace",
                searchQuery: "Residenz Munich palace museum",
                description: "The Residenz is the largest city palace in Germany — a sprawling complex of 130 rooms that served as the Wittelsbach seat of power for over five centuries. From Renaissance courtyards to rococo theaters, the palace grew with each generation of rulers, each trying to outdo the last in splendor.",
                historicalNote: "Construction began in 1385 and continued until the 19th century, resulting in an extraordinary mix of Renaissance, Baroque, Rococo, and Neoclassical styles. The Antiquarium, a vast Renaissance hall from 1571 covered in frescoes and busts, is one of the largest such rooms north of the Alps.",
                historicalFacts: [
                    HistoricalFact(year: "1385", title: "From castle to palace", content: "Construction began in 1385 around a small Wittelsbach defensive castle. Over five centuries it grew into ten courtyards and 130 rooms, blending Renaissance, Baroque, Rococo, and Neoclassical styles.", category: .architecture),
                    HistoricalFact(year: "1571", title: "The Antiquarium", content: "Duke Albrecht V built the Antiquarium in 1571 to display his collection of ancient Roman busts. Sixty-six metres long, it's one of the grandest Renaissance halls north of the Alps.", category: .art),
                    HistoricalFact(year: "1944", title: "Almost lost", content: "Allied bombing in 1944 reduced much of the Residenz to rubble. Munich rebuilt patiently across decades; the last interior — the Antiquarium ceiling — wasn't restored until 2003.", category: .event),
                    HistoricalFact(year: "1918", title: "End of the Wittelsbach reign", content: "The Wittelsbach dynasty ruled Bavaria from this complex for 738 years. King Ludwig III abdicated in November 1918 — Europe's longest-reigning royal house ended its rule almost without violence.", category: .famous)
                ],
                tip: "Buy the combined ticket for the Residenzmuseum and Treasury. The Treasury alone — with the Bavarian crown jewels and medieval goldwork — is worth the visit. Allow at least two hours.",
                durationMinutes: 25,
                iconType: "museum",
                walkingNarration: nil,
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Residenz Bronze Lions",
                        description: "At the entrance on Residenzstrasse, four bronze lion statues guard the doorway. Rubbing their noses is said to bring good luck — you can see how generations of hands have polished them to a bright sheen.",
                        searchQuery: "Residenz bronze lions Residenzstrasse Munich",
                        iconSystemName: "hand.raised.fill"
                    ),
                    TemplateDiscoveryPoint(
                        name: "Cuvillies-Theater",
                        description: "Hidden within the Residenz complex, the Cuvillies-Theater is the finest surviving Rococo theater in the world. Dripping with gilded carvings and red velvet, Mozart's Idomeneo premiered here in 1781. It still hosts performances today.",
                        searchQuery: "Cuvillies Theater Residenz Munich"
                    )
                ]
            ),
            TemplateStop(
                name: "Hofgarten",
                searchQuery: "Hofgarten Munich royal garden",
                description: "The Hofgarten is an elegant Renaissance garden directly behind the Residenz, laid out in 1613 by Duke Maximilian I. Symmetrical gravel paths radiate from a central pavilion, lined with arched walkways where locals play chess, tango dancers practice, and musicians busk beneath the frescoed arcades.",
                historicalNote: "The central pavilion, the Dianatempel, was built in 1615 and originally served as a focal point for courtly garden parties. The arcades along the north side contain historical frescoes depicting scenes from Bavarian history, recently restored to their original vibrancy.",
                historicalFacts: [
                    HistoricalFact(year: "1615", title: "An Italian garden in Munich", content: "Duke Maximilian I had the Hofgarten laid out in Italian Renaissance style in 1613–17, complete with the central Dianatempel. It was the first formal Italianate garden in Bavaria.", category: .architecture),
                    HistoricalFact(year: nil, title: "Bavaria's history in fresco", content: "The arcades along the north side carry frescoes depicting scenes from Bavarian and Wittelsbach history. The series was painted in the 1820s under Ludwig I and recently restored to its original colour.", category: .art),
                    HistoricalFact(year: nil, title: "Boules at the Diana", content: "On warm afternoons the Hofgarten fills with locals playing pétanque around the Dianatempel. The shallow gravel circles around the pavilion are unofficial pitches that nobody quite owns.", category: .culture)
                ],
                tip: "The Hofgarten is one of Munich's most peaceful spots at any time of day. On sunny afternoons, look for the impromptu tango sessions in the pavilion — a Munich tradition that delights visitors. The cafe in the arcade is a quiet alternative to busier city-center spots.",
                durationMinutes: 15,
                iconType: "park",
                walkingNarration: "Exit the Residenz through the north side and step into the Hofgarten. The transition from palatial interior to formal garden is seamless — this was by design. The Wittelsbachs wanted to walk from throne room to garden without ever leaving their world.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Hofgarten Arcades",
                        description: "The covered walkways along the garden's edges feature frescoes of Bavarian history and mythology. They also shelter a charming row of antique dealers and small galleries. On rainy days, Munchners stroll here instead of the garden paths.",
                        searchQuery: "Hofgarten Arkaden Munich",
                        iconSystemName: "paintpalette.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Theatinerkirche",
                searchQuery: "Theatinerkirche St Kajetan Munich",
                description: "This exuberant Italian baroque church, with its vivid yellow facade and twin towers, was built in 1663 to celebrate the birth of the long-awaited Wittelsbach heir, Max Emanuel. Commissioned by Elector Ferdinand Maria's wife, Henriette Adelaide of Savoy, it brought a dramatic slice of Italian architecture to Munich.",
                historicalNote: "Henriette Adelaide imported Italian architects and craftsmen to build a church that would rival those in her native Turin. The all-white stucco interior is a masterpiece of restraint and drama, and the royal crypt below holds the remains of Wittelsbach rulers including King Otto of Greece.",
                historicalFacts: [
                    HistoricalFact(year: "1663", title: "An heir's thank-you", content: "Elector Ferdinand Maria and Henriette Adelaide of Savoy began the Theatinerkirche in 1663 to thank God for the long-awaited birth of an heir. They imported Italian Theatine architects to do it right.", category: .event),
                    HistoricalFact(year: nil, title: "All-white drama", content: "The interior is one of the great restraint exercises in Italian Baroque: pure white stucco, no gold, no paintings on the ceiling. The drama comes from depth, light, and the elaborate cornices alone.", category: .architecture),
                    HistoricalFact(year: nil, title: "The Wittelsbach crypt", content: "The royal crypt below holds the remains of dozens of Wittelsbach rulers — including King Otto of Greece, who reigned in Athens from 1832 until exile in 1862, and ended up back home under his family church.", category: .famous)
                ],
                tip: "Step inside to experience the stunning contrast between the colorful exterior and the luminous white interior. The effect is breathtaking. Entry is free. The crypt is accessible and offers a moving encounter with the dynasty's history.",
                durationMinutes: 15,
                iconType: "landmark",
                walkingNarration: "Walk south from the Hofgarten through the arched passageway to Odeonsplatz. The Theatinerkirche's yellow towers announce themselves boldly against the sky — this church was never meant to be subtle.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Odeonsplatz View",
                        description: "Standing on Odeonsplatz facing south, you see the Theatinerkirche on your left, the Feldherrnhalle ahead, and the sweep of Ludwigstrasse stretching north. This is one of Munich's most perfectly composed urban views, designed to impress.",
                        searchQuery: "Odeonsplatz panorama Munich"
                    )
                ]
            ),
            TemplateStop(
                name: "Wittelsbacher Brunnen",
                searchQuery: "Wittelsbacher Brunnen Lenbachplatz Munich fountain",
                description: "This magnificent Art Nouveau fountain on Lenbachplatz, created by sculptor Adolf von Hildebrand in 1895, celebrates Munich's water supply — a fitting tribute given the Wittelsbachs' role in bringing clean water to the city. Two powerful figures sit atop cascading basins: a man on a bull representing the destructive force of water, and a woman on a horse symbolizing its healing power.",
                historicalNote: "The fountain was commissioned to celebrate the completion of Munich's modern water supply system, which brought fresh Alpine spring water to the city from the Mangfall Valley — an engineering feat funded by the Wittelsbach crown. It remains one of the finest fountains in Germany.",
                historicalFacts: [
                    HistoricalFact(year: "1895", title: "A fountain for fresh water", content: "Adolf von Hildebrand designed the Wittelsbacher Brunnen in 1895 to celebrate the completion of Munich's modern water supply, which piped Alpine spring water in from the Mangfall valley.", category: .event),
                    HistoricalFact(year: nil, title: "Two riders, two waters", content: "The two riders represent the destructive and life-giving power of water: a young man on a bull hurls a stone (the wild flood), an old woman on a horse pours water from a bowl (the calm spring).", category: .art),
                    HistoricalFact(year: nil, title: "Hildebrand the sculptor-architect", content: "Hildebrand was both architect and sculptor — unusual at the time — and considered the fountain his finest work. The composition is studied in art schools as a classic example of Greco-Roman revival.", category: .general)
                ],
                tip: "The fountain is most dramatic in the morning when sunlight catches the cascading water. It sits in a small, often-overlooked square between major sights — a quiet moment between grander stops.",
                durationMinutes: 10,
                iconType: "landmark",
                walkingNarration: "Walk west from Odeonsplatz toward Lenbachplatz. You're moving through the grand quarter the Wittelsbachs built in the 19th century to rival Paris and Vienna. The architecture grows progressively more opulent with every block.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Lenbachhaus",
                        description: "The Lenbachhaus gallery next door, housed in the Italianate villa of painter Franz von Lenbach, contains the world's largest collection of Blue Rider (Der Blaue Reiter) art — Kandinsky, Klee, Marc, and Munter. The Wittelsbachs were great art patrons, and this tradition continues.",
                        searchQuery: "Lenbachhaus Munich gallery",
                        iconSystemName: "paintpalette.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Alter Hof",
                searchQuery: "Alter Hof Munich old court Wittelsbach",
                description: "Munich's oldest royal residence, built in 1253, was the first Wittelsbach stronghold in the city. The medieval courtyard with its distinctive bay window tower (the Affenturm, or Monkey Tower) is a quiet escape from the bustle of the surrounding shopping streets. This is where the Wittelsbach story in Munich truly began.",
                historicalNote: "The Affenturm (Monkey Tower) gets its name from a legend: a pet monkey belonging to young Ludwig IV allegedly snatched the infant prince from his cradle and climbed to the tower's top, terrifying the court. The monkey eventually returned the child safely — and the future emperor went on to rule the Holy Roman Empire.",
                historicalFacts: [
                    HistoricalFact(year: "1253", title: "First Wittelsbach residence", content: "The Alter Hof was built in 1253 as the first urban residence of the Wittelsbach dukes. The court moved to the Residenz in the 14th century, but the older complex remained in royal use for centuries.", category: .architecture),
                    HistoricalFact(year: nil, title: "Emperor Ludwig held court here", content: "Ludwig IV — Holy Roman Emperor from 1328 — used the Alter Hof as his Munich seat. From these courtyards he excommunicated the Pope and was excommunicated in return.", category: .famous),
                    HistoricalFact(year: nil, title: "The monkey's legend", content: "The corner tower is called the Affenturm — Monkey Tower — for a story: a court monkey snatched the infant Ludwig IV from his cradle and climbed to the top. It returned the prince unharmed; the prince became emperor; the tower kept its name.", category: .legend)
                ],
                tip: "The small museum in the vaulted cellar (Infopoint Museen & Schlosser) is free and offers an excellent introduction to Bavarian castle and palace history. The courtyard cafe is a peaceful spot for coffee away from the crowds.",
                durationMinutes: 15,
                iconType: "historical",
                walkingNarration: "Walk east back toward the heart of the old town. The Alter Hof hides in the shadow of its grander successor, the Residenz, but this is where it all started — a fortified courtyard where a dynasty was born.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Affenturm (Monkey Tower)",
                        description: "Look up at the distinctive oriel window projecting from the tower on the south side. A relief carving near the base depicts the famous monkey legend. The tower is the oldest surviving part of the complex, dating to the 13th century.",
                        searchQuery: "Affenturm Alter Hof Munich",
                        iconSystemName: "tower.cell.broadcast.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Nationaltheater (Bavarian State Opera)",
                searchQuery: "Nationaltheater Bayerische Staatsoper Max-Joseph-Platz Munich",
                description: "The grand finale of any royal Munich tour: the Nationaltheater on Max-Joseph-Platz, home of the Bavarian State Opera and one of the world's great opera houses. The imposing Greek temple facade, completed in 1818, perfectly embodies the Wittelsbachs' vision of Munich as the 'Athens on the Isar.'",
                historicalNote: "The theater was built by King Max I Joseph, destroyed by fire in 1823, immediately rebuilt, then destroyed again by WWII bombs. Munchners again prioritized rebuilding it, reopening in 1963. Wagner premiered Tristan und Isolde, Die Meistersinger, Das Rheingold, and Die Walkure here — all under the patronage of the legendary (and possibly mad) King Ludwig II.",
                historicalFacts: [
                    HistoricalFact(year: "1818", title: "Built and burned twice", content: "Karl von Fischer's grand neoclassical opera house opened in 1818, burned to a shell five years later in 1823, was rebuilt to the same plans by Leo von Klenze, then was destroyed again by Allied bombs in 1943.", category: .event),
                    HistoricalFact(year: "1865", title: "Wagner's Munich premieres", content: "Under the patronage of the young King Ludwig II, Wagner premiered Tristan und Isolde here in 1865, then Die Meistersinger (1868), Das Rheingold (1869) and Die Walküre (1870). Bavaria nearly went bankrupt subsidising him.", category: .famous),
                    HistoricalFact(year: "1963", title: "The slow rebuild", content: "Reconstruction after WWII took twenty years and was finally completed in 1963. Munchners argued endlessly about whether to rebuild it as it had been or in a modern style. Tradition won.", category: .culture)
                ],
                tip: "Even if you don't catch a performance, walk up the steps and admire the portico — the view across Max-Joseph-Platz to the Residenz is quintessential royal Munich. For opera, check for standing-room or last-minute tickets, which are surprisingly affordable.",
                durationMinutes: 15,
                iconType: "entertainment",
                walkingNarration: "Walk the short distance to Max-Joseph-Platz. As you emerge into the square, the Nationaltheater's colossal columns come into view — the final, and perhaps most powerful, expression of what the Wittelsbachs built for their city.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Max-Joseph-Platz",
                        description: "The seated statue in the center of the square depicts King Max I Joseph, Bavaria's first king, who granted the state its first constitution in 1818. He faces the theater he built, forever watching over Munich's cultural life.",
                        searchQuery: "Max Joseph Platz statue Munich"
                    )
                ]
            )
        ],
        isSkeleton: true
    )

    static let hiddenMunich = TourTemplate(
        id: "munich_hidden",
        tourName: "Hidden Munich: Secret Spots & Quiet Wonders",
        tourDescription: "Discover the Munich most tourists never see — tucked-away baroque gems, secret courtyards, underground passages, and architectural surprises hiding in plain sight.",
        category: .munichHidden,
        narrativeThread: "Behind Munich's well-known landmarks lies a city of secrets — courtyards concealed behind unassuming doors, churches squeezed between shops, and architectural passages that reward the curious. This tour is for those who like to look where others don't.",
        guidePersona: GuidePersona(
            name: "Mia",
            tagline: "Urban explorer & design lover",
            voiceStyle: "curious, slightly conspiratorial, eye for design details, delights in surprises",
            greeting: "Servus! I'm Mia. I've spent years poking around Munich's forgotten corners, and I've found things that will surprise even locals. Ready to see the city most people walk right past? Dann mal los!",
            signoff: "Now you see Munich differently — and that's the best souvenir there is. Keep looking behind doors, above rooftops, and through courtyards. Bis bald!"
        ),
        stops: [
            TemplateStop(
                name: "Asamkirche",
                searchQuery: "Asamkirche Sendlinger Strasse Munich",
                description: "Our hidden tour begins with Munich's most spectacular secret-in-plain-sight. The Asamkirche is wedged between ordinary shops on a busy street, and many people walk right past its narrow baroque facade. Step inside and the explosion of gold, frescoes, and theatrical light will take your breath away. The Asam brothers built it as their private chapel — and they held nothing back.",
                historicalNote: "The church was built between 1733 and 1746 by brothers Cosmas Damian (painter) and Egid Quirin Asam (sculptor/architect), who owned the neighboring houses and designed the church for their personal devotion. Public pressure forced them to open it, and Munich has been grateful ever since.",
                historicalFacts: [
                    HistoricalFact(year: "1733", title: "A private project, then public", content: "The Asam brothers — a painter and a sculptor — built this church between 1733 and 1746 next to their houses for their personal devotion. Public pressure forced them to open it.", category: .event),
                    HistoricalFact(year: nil, title: "Late Bavarian Baroque concentrated", content: "Only nine metres wide, the Asamkirche packs every Baroque trick into a tiny room: gilded stucco, ceiling frescoes, marbled columns, dramatic side-lighting. Considered the finest small Baroque interior south of the Danube.", category: .architecture),
                    HistoricalFact(year: nil, title: "The window from the bedroom", content: "Egid Quirin Asam's house next door had a small private window looking onto the high altar so he could attend Mass without leaving home. The window is still visible from inside the church.", category: .culture)
                ],
                tip: "Visit in the morning when angled sunlight enters the hidden windows, illuminating the altar in a golden glow. The architects designed this light effect deliberately — it's pure theater. Free entry, and it takes only ten minutes to see, but you'll want longer.",
                durationMinutes: 15,
                iconType: "landmark",
                walkingNarration: nil,
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Sendlinger Strasse Facades",
                        description: "Look carefully at the buildings flanking the Asamkirche — the houses on either side were owned by the Asam brothers. One still bears decorative stucco from the 18th century. The contrast between the ornate church entrance and the ordinary shops is what makes this spot so delightfully hidden.",
                        searchQuery: "Sendlinger Strasse Asamkirche facades Munich"
                    )
                ]
            ),
            TemplateStop(
                name: "Sendlinger Tor",
                searchQuery: "Sendlinger Tor Munich medieval gate",
                description: "One of only three surviving medieval gates in Munich's old fortifications, the Sendlinger Tor is often rushed past by shoppers heading to the pedestrian zone. But pause and look: the central arch and flanking towers date to 1318, and the passage beneath has witnessed nearly every chapter of Munich's history — medieval merchants, royal processions, and wartime refugees all passed through here.",
                historicalNote: "Munich's medieval city wall once had four main gates. The Sendlinger Tor was the southern entrance, leading to the road to Sendling and Italy beyond. The Nazis held propaganda marches through this gate; later, Munich's liberation came through it.",
                historicalFacts: [
                    HistoricalFact(year: "1318", title: "The southern gate", content: "First mentioned in 1318, the Sendlinger Tor guarded the southern entrance to Munich's medieval wall. Travellers heading toward Italy crossed the Alps after passing under this arch.", category: .architecture),
                    HistoricalFact(year: "1808", title: "Two arches lost, restored", content: "King Max Joseph had the gate's two side arches removed in 1808 to ease traffic. They were reconstructed in 1906 to the original design, which is why the masonry colours don't quite match.", category: .general),
                    HistoricalFact(year: "1945", title: "Liberation", content: "American forces entered Munich through this gate on 30 April 1945. The same arch had hosted Nazi propaganda parades a decade earlier.", category: .event)
                ],
                tip: "Stand inside the archway and look up — the vaulted ceiling and worn stone show their 700 years of age. For a great photo, frame the view through the gate toward Sendlinger Strasse. At night, the floodlit gate is particularly atmospheric.",
                durationMinutes: 10,
                iconType: "historical",
                walkingNarration: "Walk south down Sendlinger Strasse. The street narrows as it approaches the old city wall, and the twin towers of the Sendlinger Tor emerge between the buildings ahead like sentinels from another century.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "City Wall Fragment",
                        description: "Look to the left of the gate — a short stretch of Munich's original medieval city wall survives, embedded in later buildings. These thick stone walls once encircled the entire old town. Trace them with your eyes and imagine the medieval city within.",
                        searchQuery: "Munich medieval city wall Sendlinger Tor",
                        iconSystemName: "building.columns.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Alter Hof — Secret Courtyard",
                searchQuery: "Alter Hof Munich courtyard Affenturm",
                description: "Most visitors to the Alter Hof glance at the medieval facade and move on. But step through the archway into the inner courtyard, and you discover Munich's oldest royal residence — a quiet stone courtyard with the fairy-tale Affenturm (Monkey Tower) and its half-timbered bay window jutting overhead. There's a second, even more hidden courtyard beyond that most people never find.",
                historicalNote: "The Alter Hof was the first Wittelsbach residence in Munich, built around 1253. Emperor Ludwig IV — the Holy Roman Emperor — held court here. The building survived centuries of war and redevelopment, and its inner courtyards preserve a medieval atmosphere that's vanished from the rest of the old town.",
                historicalFacts: [
                    HistoricalFact(year: "1253", title: "The first urban castle", content: "Built around 1253, the Alter Hof was the first Wittelsbach residence inside Munich's walls. Earlier dukes had ruled from Burg Trausnitz in Landshut.", category: .architecture),
                    HistoricalFact(year: nil, title: "An emperor's daily life", content: "Emperor Ludwig IV ran the Holy Roman Empire from these courtyards. Imperial documents that shaped 14th-century Europe were drafted in rooms behind these unadorned brick walls.", category: .famous),
                    HistoricalFact(year: nil, title: "Vaulted cellars beneath", content: "Below the courtyard run vaulted brick cellars — once storage for the ducal court, now a small free museum. They preserve some of the oldest interior brickwork in Munich.", category: .general)
                ],
                tip: "Walk past the first courtyard through the passage on the far side to find the second, smaller courtyard. It's remarkably quiet and often completely empty. The vaulted cellar beneath houses a free museum about Bavarian castles.",
                durationMinutes: 15,
                iconType: "historical",
                walkingNarration: "Head north back into the old town's core. The Alter Hof is surrounded by modern shops and offices, making it easy to miss. Look for the medieval stone archway between Burgstrasse and Hofgraben — that's your portal to a quieter century.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Alter Hof Vaulted Cellar",
                        description: "Beneath the courtyard, a beautifully restored Gothic vaulted cellar hosts the Infopoint Museen & Schlosser. It's free, cool on hot days, and the vaulting alone is worth ducking in for. The exhibition covers Bavaria's castles and palaces.",
                        searchQuery: "Alter Hof Gewolbe Munich cellar museum",
                        iconSystemName: "building.2.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Salvatorkirche",
                searchQuery: "Salvatorkirche Munich Greek Orthodox church",
                description: "This Gothic gem from 1494 sits almost invisibly next to the bombastic Theatinerkirche. Originally a cemetery chapel, it's been Munich's Greek Orthodox church since 1829. Push open the heavy door and you're transported: Byzantine icons, golden mosaics, and the lingering scent of incense fill a soaring Gothic space. It's one of Munich's most unexpected and atmospheric interiors.",
                historicalNote: "King Ludwig I gave the church to Munich's Greek community — a testament to his obsession with Greek culture (he also sent his son Otto to become King of Greece). The blending of Gothic architecture with Orthodox liturgical art creates something genuinely unique in Europe.",
                historicalFacts: [
                    HistoricalFact(year: "1494", title: "A late-Gothic small church", content: "The Salvatorkirche was completed in 1494 in late-Gothic brick — Munich's standard building material when stone was scarce. Its unusual horseshoe ground plan was unusual for the time.", category: .architecture),
                    HistoricalFact(year: "1828", title: "Given to the Greeks", content: "King Ludwig I gave the church to Munich's small Greek Orthodox community in 1828 — the same Ludwig who four years later sent his teenage son Otto to be the first king of independent Greece.", category: .famous),
                    HistoricalFact(year: nil, title: "Gothic walls, Byzantine icons", content: "Step inside and the contrast hits immediately: Bavarian late-Gothic brick walls hung with Byzantine icons, Orthodox iconostasis, and incense lamps. There's nothing else quite like it in Germany.", category: .culture)
                ],
                tip: "Try to visit when the church is open for worship — the chanting echoing through the Gothic vaults is otherworldly. Even from outside, the contrast between this modest brick church and the grand Theatinerkirche next door tells a story about Munich's layers.",
                durationMinutes: 10,
                iconType: "historical",
                walkingNarration: "Walk north to the area behind the Theatinerkirche. Everyone photographs the grand yellow facade, but almost nobody notices the small, dark-brick church hiding in its shadow just around the corner. That's exactly where we're going.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Promenadeplatz",
                        description: "The quiet square nearby, Promenadeplatz, features a curious collection of bronze character statues on its benches — including one of Michael Jackson, added by fans after his death. He always stayed at the nearby Bayerischer Hof hotel. It's wonderfully unexpected.",
                        searchQuery: "Promenadeplatz Michael Jackson statue Munich",
                        iconSystemName: "music.note"
                    )
                ]
            ),
            TemplateStop(
                name: "Literaturhaus Courtyard",
                searchQuery: "Literaturhaus Munich Salvatorplatz courtyard",
                description: "Through an easy-to-miss entrance on Salvatorplatz, a serene Renaissance courtyard reveals itself — home to the Literaturhaus, Munich's literary center. The vaulted ground floor houses a lovely cafe, and the courtyard, surrounded by creamy stone arcades, feels like stepping into a Florentine palazzo. It's one of the most peaceful spots in the city center.",
                historicalNote: "The building served as a school for centuries before becoming Munich's literary center. The courtyard's Renaissance proportions and arcaded galleries date from the 16th century and were carefully restored after wartime damage.",
                historicalFacts: [
                    HistoricalFact(year: "1574", title: "A Jesuit grammar school", content: "Built starting in 1574, the building was for centuries the Wilhelmsgymnasium — Munich's flagship Jesuit grammar school where countless Bavarian writers and scholars were educated.", category: .general),
                    HistoricalFact(year: nil, title: "Where Munich talks about books", content: "Since 1997 the building has been the Literaturhaus — Munich's home for readings, debates, and literary festivals. The downstairs café opens onto the Renaissance courtyard.", category: .culture),
                    HistoricalFact(year: nil, title: "The arcaded courtyard survived", content: "The Renaissance arcades around the courtyard were heavily damaged in WWII and reconstructed from photographs and the original drawings. The result is one of the best surviving Renaissance courtyards in central Munich.", category: .architecture)
                ],
                tip: "The Literaturhaus cafe, Oskar Maria, is a hidden gem — excellent coffee, quiet atmosphere, and a beautiful courtyard terrace in summer. Named after Munich writer Oskar Maria Graf, it attracts writers and readers rather than tourists.",
                durationMinutes: 15,
                iconType: "landmark",
                walkingNarration: "Continue around Salvatorplatz, keeping your eyes on the building facades. The entrance to the Literaturhaus courtyard is modest — just an archway that could belong to any office building. But what lies beyond is anything but ordinary.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Salvatorplatz Atmosphere",
                        description: "This small square is one of Munich's quietest central spaces. The combination of the Greek church, the Literaturhaus, and the absence of shops creates an oasis of calm. Locals come here to read, think, and escape.",
                        searchQuery: "Salvatorplatz Munich",
                        iconSystemName: "book.fill"
                    )
                ]
            ),
            TemplateStop(
                name: "Funf Hofe Passage",
                searchQuery: "Funf Hofe Munich shopping passage architecture",
                description: "Our hidden tour ends with a modern secret: the Funf Hofe (Five Courts), a stunning contemporary passage that threads through an entire city block connecting five interconnected courtyards. Designed by Swiss architects Herzog & de Meuron, the passage features hanging gardens, a spiraling art installation, and light that filters through perforated metal screens. It proves that Munich's tradition of hidden courtyards is alive and evolving.",
                historicalNote: "Completed in 2003, the Funf Hofe transformed a formerly closed city block into a public passage. The architects deliberately referenced Munich's historic courtyard tradition while creating something radically contemporary. The hanging garden by Tita Giese suspends lush planting above shoppers' heads in a cascade of green.",
                historicalFacts: [
                    HistoricalFact(year: "2003", title: "Five courtyards, one block", content: "Swiss architects Herzog & de Meuron stitched five new courtyards through a former bank block in the heart of Munich, completed in 2003. The passage opens what had been a closed city block to the public.", category: .architecture),
                    HistoricalFact(year: nil, title: "Hanging gardens of Tita Giese", content: "The German garden artist Tita Giese designed the hanging garden cascading from the canopy in the central court. Vines and tropical plants hang in long cylinders above shoppers' heads, deliberately disorientating.", category: .art),
                    HistoricalFact(year: nil, title: "A Munich tradition, modernized", content: "The architects framed the project as a modern echo of Munich's old Höfe — the inner courtyards that hide behind every nondescript Altstadt facade. The five new courts deliberately quote that scale.", category: .culture)
                ],
                tip: "Walk slowly through all five courts and notice how each has a different character — different light, materials, and atmosphere. The hanging garden courtyard is the showstopper, but the spiral by Olafur Eliasson in the Viscardihof is equally mesmerizing. Best appreciated on a sunny day when light plays through the screens.",
                durationMinutes: 15,
                iconType: "landmark",
                walkingNarration: "Walk south toward Theatinerstrasse. We're going to end our hidden Munich tour by proving that the city's love affair with concealed courtyards didn't end in the baroque era. What you're about to walk through opened in 2003, and it's magnificent.",
                discoveryPoints: [
                    TemplateDiscoveryPoint(
                        name: "Hanging Gardens",
                        description: "Look up as you pass through the main court — thousands of plants cascade from suspended containers high above, creating a living green ceiling. Landscape artist Tita Giese designed this urban jungle to change with the seasons, offering different colors and textures year-round.",
                        searchQuery: "Funf Hofe hanging garden Munich",
                        iconSystemName: "leaf.fill"
                    ),
                    TemplateDiscoveryPoint(
                        name: "Kunsthalle Munich",
                        description: "Tucked inside the Funf Hofe, the Kunsthalle der Hypo-Kulturstiftung hosts world-class temporary exhibitions in a surprisingly intimate space. Check the current show — the exhibitions here are consistently excellent and far less crowded than Munich's major museums.",
                        searchQuery: "Kunsthalle Hypo Kulturstiftung Funf Hofe Munich",
                        iconSystemName: "paintpalette.fill"
                    )
                ]
            )
        ],
        isSkeleton: true
    )
}
