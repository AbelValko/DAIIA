/**
* Name: NewModel
* Based on the internal empty template. 
* Author: Abel Valko, Kishore Kumar
* Tags: 
*/


model NewModel

/* Insert your model definition here */

global {
		int numberOfAudience <- 10;
		int numberOfStages <- 4;
		int numberOfAttributes <- 6;
		
		
		list parts;
		
		init{
			//list items <- ["Lighting", "Sound","Genre", "Band", "Popularity", "Cleanliness"];
			
			
			create Stage number:1 with:(color:#black, location:{15,15});
			create Stage number:1 with:(color:#blue, location:{85,15});
			create Stage number:1 with:(color:#red, location:{15,85});
			create Stage number:1 with:(color:#yellow, location:{85,85});
			create Audience number: numberOfAudience returns: ps;
			
			write '---Simulation started with ' + numberOfAudience + ' audience and ' + numberOfStages + ' stages---';
			
			parts <- ps; //list of all participants
			

			
			write "---Participant interests and prices---";
			Audience[0].myPreferences <- [0.1,0.2,0.3,0.25,0.7,0.4];
			Audience[1].myPreferences <- [0.7,0.3,0.2,0.1,0.25,0.3];
			Audience[2].myPreferences <- [0.23,0.16,0.8,0.47,0.54,0.1];
			Audience[3].myPreferences <- [0.1,0.2,0.3,0.25,0.7,0.4];
			Audience[4].myPreferences <- [0.20,0.8,0.35,0.5,0.1,0.0];
			Audience[5].myPreferences <- [0.3,0.1,0.0,0.28,0.6,0.1];
			Audience[6].myPreferences <- [0.6,0.3,0.4,0.5,0.3,0.9];
			Audience[7].myPreferences <- [0.8,0.4,0.2,0.9,0.0,0.2];
			Audience[8].myPreferences <- [0.3,0.1,0.8,0.2,0.4,0.45];
			Audience[9].myPreferences <- [0.5,0.3,0.1,0.5,0.7,0.2];
			
			loop p from:0 to:numberOfAudience-1{
				write "Audience " + p;
				write Audience[p].myPreferences;
			}
			
			loop p from:0 to:numberOfAudience-1{
				map<string,float> utilityValues <- nil;
				loop i from:0 to:length(Stage)-1{
					float  score <- 0.0;
					add score at: Stage[i].name to:utilityValues;
					}
				Audience[p].utilityValues <- utilityValues;
				write "Audience " + p;
				write utilityValues;
			}
				
		}
}


species Stage skills: [fipa] {
	
	rgb color;
	list<float> actAttribute;
	
	aspect base {
		
		draw square(4) color:color;
	}
	
	reflex change_attributes when:(time mod 50 = 0){
		//Sends request to all participants to join auction.	
		write name + ': Flipping attributes for new act';
		actAttribute <-[];
		loop times: numberOfAttributes{
			actAttribute << rnd(10)/10;
		}
		write name + ': Attributes for new act'+actAttribute;	
	}
	
		
	reflex informsHandler when: (!empty(informs)) {
		write '(Time ' + time + '): ' + name + ' received requests';

		loop p over: informs {
				write '\t' + name + ' receives an inform message from ' + agent(p.sender).name + ' with content ' + p.contents ;
				list content <- p.contents;
				if (content[0] = "Need Attributes"){
					do inform message:p contents:actAttribute;
				}
			}
		}
}

species Audience skills: [moving,fipa]{
	
	list<float> myPreferences <- nil;
	Stage targetStage <- nil;
	point targetLocation;
	bool reached <- false;
	map<string,float> utilityValues <- nil;
	int speedVal <- rnd(1,3);
	
	
	aspect base {
		rgb agentcolor <- rgb("grey");
		if targetStage = nil{
			agentcolor <- rgb("grey");
		} else{
			agentcolor <- targetStage.color;
		}
		
		draw circle(1) color:agentcolor;
	}
	
	reflex requestActValues when: time mod 50 = 0 {
		write name + ': Asking each stage for attributes of the new acts';
		do start_conversation (to::list(Stage), protocol :: 'fipa-request', performative :: 'inform', contents :: ["Need Attributes"]);	

	}
	
	reflex goToTarget when: !(targetLocation = location) and !(targetLocation=nil){
		reached <- false;
		do goto target:targetLocation speed: speedVal;
		write name+" Moving to target location:"+targetLocation;
	}
	
	reflex reachedTarget when: (targetLocation = location) and !(targetLocation=nil){
		write "Reached target Location";
		reached <- true;
		targetLocation <- nil;
		targetStage <- nil;
		loop i from:0 to:length(Stage)-1{
				float  score <- 0.0;
				add score at: Stage[i].name to:utilityValues;
		} 
	}
	
	reflex receiveAndSetGoal when: !empty(informs) {
		write '(Time ' + time + '): ' + name + ' receives inform messages';
		loop i over: informs {
			list<float> contents <- i.contents;
			string senderName <- agent(i.sender).name;
			write '\t' + name + ' receives an inform message from ' +senderName + ' with content ' + contents ;
			int counter <- 0;
			
			loop content over: contents {
				utilityValues[senderName] <- utilityValues[senderName] + contents[counter] * myPreferences[counter];
				counter <- counter+1;
				
			}
			
		}
		write '(Time ' + time + '): ' + name + ' Utility values are:'+ utilityValues +" Max value is:"+max(utilityValues);
		float maxUtility <- max(utilityValues);
		loop ctr from:0 to:numberOfStages-1{
				if utilityValues[Stage[ctr].name] = maxUtility{
					targetLocation <- Stage[ctr].location;
					write name+": Target found!:"+Stage[ctr].name+" Location:"+targetLocation;
					targetStage <- Stage[ctr];
					
					
				}
				
				
			}
		
	}
	
}

experiment MyExperiment type:gui {
	output {
		display Festival {
			// Display the species with the created aspects
			species Audience aspect:base;
			species Stage aspect:base;
		}
	}
	
}

