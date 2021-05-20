Calin-Andrei Bucur
332CB

Tema 2 ASC

Implemementare blas:
La inceput a fost cam greu de lucrat cu documentatia aia veche de fortran.
Nu sunt prea multe de spus.
Aloc matricea rezultat C si o matrice auxiliara pt A * B pe care o eliberez la sfarsit
Inmultesc At * A folosind dtrmm pentru a tine cont de faptul ca A e triangulata
(ii specific toate cele si anume faptul ca e Row Major, sa inmulteasca in partea stanga (mergea si invers), faptul ca At e triangulata superior apoi transpusa si dimensiunile)
Inmultesc A * B folosind aceasi functie din aceleasi considerente
Calculez rezultatul final folosind dgemm pt a efectua AB * Bt + AtA. Ma gandeam sa folosesc dsymm pentru a profita de simetria matricelor AtA si BBt dar am renuntat, nu mi s-a parut worth.

Implementarea neoptimizata:
Trebuie sa recunosc ca aici am fost putin neglijent/ineficient intentionat
Am ales sa implementez functii pt fiecare operatie si sa calculez rezultatul final prin apeluri ale acestor functii
Am o functie care transpune o matrice in modul clasic
Am o functie care inmulteste o matrice superior triangulata cu o matrice oarecare. Initializez matricea rezultat cu 0 si fac adunarile direct in elementul respectiv. Fiind vorba de o matrice superior triangulata loop-ul interior poate fi de la [i:N).
Am o functie care inmulteste o matrice inferior triangulata cu o matrice oarecare. La fel ca mai sus dar loop-ul se duce in range-ul [0,i].
Am o functie care inmulteste clasic 2 matrice oarecare.
In functia solver, aflu At si Bt dupa care fac inmultirile folosind functiile de mai sus iar in cele din urma fac de mana adunarea.

Implementarea optimizata:
Dupa cum se vede in implementarea neoptimizata fiecare functie e apelata o singura data.
Aici am ales sa renunt la functii si sa scriu direct codul ca sa vad daca apelurile de functie incetinesc codul (they kinda do just a bit).
* Am doi pointeri folositi cam in toate calculele pt a reduce accesele la memorie. Incerc sa accesez elementele in dereferentiind acesti pointeri (nu ca la arrays) si sa nu fac cat mai putine calcule. line imi indica linia din matricea sursa/stanga la care ma aflu, iar res indica linia/coloana din rezultat la care scriu.
* De asemenea, cam la toate calculele majoritatea variabilelor sunt register pt eficienta sporita.
* Din nou cam la toate calculele pt a "deplasa" pointerii pe linii/coloane ii incrementez fie cu N fie cu 1
* Avand At si Bt calculate, prefer ca la fiecare inmultire sa inmultesc liniile cu liniile transpusei, rezultatul fiind acelasi dar este mai eficient deoarece C este Row Major si parcurgerea pe linii e mai eficienta.
Mai intai calculez At:
* Initializez At cu 0 cu calloc (mai costisitor decat malloc dar imi convine mai mult sa fie zeroizata, rezultatul fiind o matrice inferior triangulata deci de jumatate din zerouri nu ma mai ating)
* Calculez transpusa tinand cont de faptul ca A e triangulata superior (loopul interior de la i la N)
Calculez Bt:
* Aloc Bt (de data asta cu malloc caci voi suprascrie toate elementele anyway)
* Procedez la fel ca la At dar nu mai am proprietatea de la triangulata deci loopul interior merge de la 0 la N
Calculez At * A:
* In inmultire tin cont de faptul ca At e inferior triangulata la fel ca la varianta neoptimizata
* De asemenea am o variabila sum in care tin rezultatul partial al fiecarui element si scriu doar rezultatul final in matrice pt a scadea nr de accese la memorie
Calculez A * B ca mai sus dar tinand cont de faptul ca A e superior triangulata
La calculul final:
* Initializez rezultatul final ca fiind AtA. Cand calculez fiecare element, in loc sa il suprascriu in rezultat, il adun. Astfel scap de inca 1 for in care as fi facut adunarea.
* De asemenea, aici nu mai am matrice triangulate, deci loopul interior are de fiecare data N iteratii si am ales sa fac loop unrolling (4 iteratii)
Mentionez ca pt N = 1200 solutia obtine 6pct bonus (sunt foarte multumit, I thought I sucked at optimizing). As fi putut sa mai incerc reordonarea loop-urilor si BMM, dar prefer sa iau cele 10 pct bonus ca trimit mai repede decat sa ma chinui pt inca 4pct :))

Ca si concluzii pe baza graficului:
* Varianta neoptimizata e FOARTE ineficienta, timpul urca foarte repede
* Varianta optimizata se misca semnificativ mai bine si sincer e mai aproape de blas decat ma asteptam, dar pe masura ce creste inputul incepe sa se departeze mai mult.
* Ambele variante mananca praful din urma lui blas. Am ramas surprins la ce rapid e si se pare ca a fost chiar useful sa il invatam.
* Blas asta zici ca e Usain Bolt smr :))