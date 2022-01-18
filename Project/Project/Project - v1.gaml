/**
* Name: FinalProject
* Based on the internal empty template. 
* Author: Abel Valko, Kishore Kumar
* Tags: 
*/


/*
 * Suggested Solution:
 * 
 * Initiate position of places to ensure they are far away from eachother. Perhaps make area larger?
 * Initiate all Persons. Each person chooses a place to go to at random and moves to it.
 * Each person wanders.
 * When a person (not already in an interaction, ie with no waiting fipa messages) gets close enough to another person they begin an interaction
 * Person initiating sends fipa message with their interest. Other replies.
 * Personality trait scores are exchanged the same way as interests.
 * Once both parties know all traits of the other, their happiness is updated (calculateInteractionEffect) using these scores.
 * If a Person has had 2 (or more? consequtive encounters with outcome <0 they move to other location
 * Otherwise, the Person continues to wander and interacts with other Persons
 * Persons should not interact while moving between places
 * 
 */

model FinalProject

global {
	float globalHappinessScore <- 0.0;
	
	// Define number of each type of person
	int partyPersonCount <- 10;
	int sportsPersonCount <- 10;
	int historyPersonCount <- 10;
	int readingPersonCount <- 10;
	int gamingPersonCount <- 10;
	
	// map for defining how each location modulates the importance of personality traits. Eg. adherency is more important in museum than in pub
	map<string,map> placeTraitModifiers <- create_map(['pub', 'museum'],
		[create_map(['gen', 'loud', 'adh'],[2,0.5,0.5]),
		create_map(['gen', 'loud', 'adh'],[0.5, 2, 2])
		]
	);
	// map for defining how each location modulates the experience of each type of person. The value is added to the interaction effect.
	map<string, map> typePlaceModifiers <- create_map(['party', 'sports', 'history', 'reading', 'gaming'], 
		[create_map(['pub', 'museum'],[1,-1]),
		create_map(['pub', 'museum'],[1,0]),
		create_map(['pub', 'museum'],[0.5, 1]),
		create_map(['pub', 'museum'],[-0.5, 1]),
		create_map(['pub', 'museum'],[0.5, 0.5])	
		]
	);
	
	int personCount <- partyPersonCount + sportsPersonCount + historyPersonCount + readingPersonCount + gamingPersonCount;
	
	init {
		// Create persons and places of all types
		create Person number:partyPersonCount with:(type:"party");
		create Person number:sportsPersonCount with:(type:"sports");
		create Person number:historyPersonCount with:(type:"history");
		create Person number:readingPersonCount with:(type:"reading");
		create Person number:gamingPersonCount with:(type:"gaming");
		create Place number:1 with:(type:"pub");
		create Place number:1 with:(type:"museum");
		
		loop p over:Person{
			//randomize personality scores
			p.generosityScore <- rnd(-1.0,1.0,0.05);
			p.loudnessScore <- rnd(-1.0,1.0,0.05);
			p.adherencyScore <- rnd(-1.0,1.0,0.05);
		}
	}
	
	reflex updateGlobalHapiness{
		// Calculates average happiness of all People species
		float total <- 0.0;
		loop p over:Person{
			total <- total + p.happinessScore;
		}
		globalHappinessScore <- total / personCount;
		write "GLOBAL HAPPINESS AVERAGE: " + globalHappinessScore;
	}
}

species Person skills:[fipa, moving]{
	string type;
	float generosityScore;
	float loudnessScore;
	float adherencyScore;
	float happinessScore <- 0.0; 
	
	action calculateInteractionEffect(string place, string typePar, float genPar, float loudPar, float adhPar){
		/*
		 * Calculates effect of an interaction with given parameters for 
		 * location, type, generosity, loudness, adherence from other person (partner)
		 * and updates happinessScore accordingly
		 * 
		 * INPUT: place, interaction partner's type, partner's generocityScore, partner's loudnessScore, partner's adherencyScore
		 * OUTPUT: None
		 */
		 
		 // Modifier based on type compatibility
		 float typeModifier <- 0.0;
		 if type ="party" {
		 	if typePar = "party"{typeModifier<-1.0;}
		 	else if typePar="sports"{typeModifier<-0.5;}
		 } else if type="sports" {
		 	if typePar = "sports"{typeModifier<-1.0;}
		 	else if typePar="party" or typePar="gaming"{typeModifier<-0.5;}
		 } else if type="reading" {
		 	if typePar = "reading"{typeModifier<-1.0;}
		 	else if typePar = "history" or typePar = "gaming"{typeModifier<-0.5;}
		 } else if type="history" {
		 	if typePar = "history"{typeModifier<-1.0;}
		 	else if typePar="reading" or typePar="gaming"{typeModifier<-0.5;}
		 } else if type="gaming" {
		 	if typePar = "gaming"{typeModifier<-1.0;}
		 	else if typePar="history" or typePar="sports" or typePar="reading"{typeModifier<-0.5;}
		 }
		 
		 float genModifier;
		 if genPar < 0 and generosityScore < 0 {
		 	genModifier <- -1 * genPar * generosityScore;
		 } else if genPar < 0 or generosityScore < 0 {
		 	genModifier <- -0.5 * genPar * generosityScore;
		 } else {
		 	genModifier <- genPar * generosityScore;
		 }
		 
		 float loudPlaceMod <- float(placeTraitModifiers[place]['loud']);
		 float loudModifier <- float(placeTraitModifiers[place]['loud']) * loudPar * loudnessScore;
		 float adhModifier <- float(placeTraitModifiers[place]['adh']) * adhPar * adherencyScore;
		 genModifier <- float(placeTraitModifiers[place]['gen']) * genModifier;
		 
		 float effect <- float(typePlaceModifiers[type][place]) + loudModifier + adhModifier + genModifier;
		 
		 // TODO: typeModifier is not added yet!!!
		 // TODO: check that this arbitrary calculation makes somewhat sense
		 
		 happinessScore <- happinessScore + effect;
	}
	
	aspect default {
		if type="party" {
			draw circle(0.5) color:#blue;
		} else if type="sports" {
			draw circle(0.5) color:#red;
		} else if type="reading" {
			draw circle(0.5) color:#yellow;
		} else if type="history" {
			draw circle(0.5) color:#green;
		} else if type="gaming" {
			draw circle(0.5) color:#purple;
		}
	}
}

species Place {
	string type;
	
	aspect default {
		if type="pub" {
			draw triangle(3) color:#black;
		} else if type="museum" {
			draw square(3) color:#black;
		}
	}
}

experiment MyExperiment type:gui{
	output {
		display MyDisplay type:java2D {
			species Place aspect:default;
			species Person aspect:default;
			// Add species
		}
	}
}