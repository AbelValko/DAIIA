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
		int numberOfAttributes <- 7;
		
		
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
			Audience[0].myPreferences <- [0.1,0.2,0.3,0.25,0.7,0.4,-0.2];
			Audience[1].myPreferences <- [0.7,0.3,0.2,0.1,0.25,0.3,0.4];
			Audience[2].myPreferences <- [0.23,0.16,0.8,0.47,0.54,0.1,0.3];
			Audience[3].myPreferences <- [0.1,0.2,0.3,0.25,0.7,0.4,0.4];
			Audience[4].myPreferences <- [0.20,0.8,0.35,0.5,0.1,0.0,0.7];
			Audience[5].myPreferences <- [0.3,0.1,0.0,0.28,0.6,0.1,0.8];
			Audience[6].myPreferences <- [0.6,0.3,0.4,0.5,0.3,0.9,0.1];
			Audience[7].myPreferences <- [0.8,0.4,0.2,0.9,0.0,0.2,0.1];
			Audience[8].myPreferences <- [0.3,0.1,0.8,0.2,0.4,0.45,0.1];
			Audience[9].myPreferences <- [0.5,0.3,0.1,0.5,0.7,0.2,0.2];
			
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
	int endsAt <- 0;
	list<Audience> guestsList <- parts;
	
	aspect base {
		
		draw square(4) color:color;
	}
	
	reflex change_attributes when:(time = endsAt){
		//Sends request to all participants to join auction.	
		actAttribute <-[];
		loop times: numberOfAttributes-1{
			actAttribute << rnd(10)/10;
		}
		actAttribute << 0.0;
		endsAt <- time + rnd(200,250);
		write '(Time ' + time + '): ' + name + ': Beginning a new act with attributes: '+actAttribute+" till time:"+endsAt;
		if time = 0{
			do start_conversation (to::list(Audience), protocol :: 'fipa-request', performative :: 'inform', contents :: ["New Act",actAttribute]);
		}
		else{
			if (length(guestsList) > 0){
				do start_conversation (to::guestsList, protocol :: 'fipa-request', performative :: 'inform', contents :: ["New Act",actAttribute]);
			}
		}
		guestsList <- [];	
	}
	
		
	reflex informsHandler when: (!empty(informs)) {
		write '(Time ' + time + '): ' + name + ' received requests';

		loop p over: informs {
				write '\t' +'(Time ' + time + '): ' + name + ' receives an inform message from ' + agent(p.sender).name + ' with content ' + p.contents ;
				list content <- p.contents;
				if (content[0] = "Need Attributes"){
					do inform message:p contents:["Ongoing Act",actAttribute];
				}
			}
		}
}

species Audience skills: [moving,fipa]{
	
	list<float> myPreferences <- nil;
	Stage targetStage <- nil;
	point targetLocation;
	bool reached <- false;
	bool actEnded <- false;
	map<string,float> utilityValues <- nil;
	int speedVal <- rnd(5,10);
	
	
	aspect base {
		rgb agentcolor <- rgb("grey");
		if targetStage = nil{
			agentcolor <- rgb("grey");
		} else{
			agentcolor <- targetStage.color;
		}
		
		draw circle(1) color:agentcolor;
	}
	
	reflex requestActValues when: ((time mod 5 = 0) and flip(0.5) and !(time = 0)){
		write '(Time ' + time + '): ' + name + ': Asking each stage for attributes of the new acts';
		loop i from:0 to:length(Stage)-1{
				float  score <- 0.0;
				add score at: Stage[i].name to:utilityValues;
		}
		do start_conversation (to::list(Stage), protocol :: 'fipa-request', performative :: 'inform', contents :: ["Need Attributes"]);	

	}
	
	reflex goToTarget when: !(targetLocation = location) and !(targetLocation=nil){
		reached <- false;
		do goto target:targetLocation speed: speedVal;
		//write name+" Moving to target location:"+targetLocation;
	}
	
	reflex reachedTarget when: (targetLocation = location) and !(targetLocation=nil){
		write '(Time ' + time + '): ' + name +" Reached target Location";
		reached <- true;
		targetLocation <- nil;
		targetStage.guestsList <+ self;
		targetStage.actAttribute[6] <- length(targetStage.guestsList)/10;
		loop i from:0 to:length(Stage)-1{
				float  score <- 0.0;
				add score at: Stage[i].name to:utilityValues;
		} 
	}
	
	reflex receiveMessages when: !empty(informs) {
		write '(Time ' + time + '): ' + name + ' receives inform messages';
		loop i over: informs {
			list values <- i.contents;
			string msg <- values[0];
			list<float> contents <- values[1];
			string senderName <- agent(i.sender).name;
			write '\t' + '(Time ' + time + '): ' + name + ' receives an inform message from ' +senderName + ' with content ' + contents ;
			if ((msg = "New Act") and !(time = 1)){
				write '(Time ' + time + '): ' + name+" Act ended in Stage:"+senderName+". Asking each stage for attributes to move on to the next stage.";
				loop i from:0 to:length(Stage)-1{
					float  score <- 0.0;
					add score at: Stage[i].name to:utilityValues;
				}
				do start_conversation (to::list(Stage), protocol :: 'fipa-request', performative :: 'inform', contents :: ["Need Attributes"]);
				actEnded <- true;	
				break;
			}
			else{
				int counter <- 0;
			
				loop content over: contents {
					//write name+" "+ contents[counter]+" "+ myPreferences[counter];
					utilityValues[senderName] <- utilityValues[senderName] + contents[counter] * myPreferences[counter];
					counter <- counter+1;
				
				}
				actEnded <- false;
			}
			
			
		}
		if !(actEnded){
			write '(Time ' + time + '): ' + name + ' Utility values are:'+ utilityValues +" Max value is:"+max(utilityValues);
			float maxUtility <- max(utilityValues);
			loop ctr from:0 to:numberOfStages-1{
				if utilityValues[Stage[ctr].name] = maxUtility{
					targetLocation <- Stage[ctr].location;
					write '(Time ' + time + '): ' + name+": Target found!:"+Stage[ctr].name+" Location:"+targetLocation;
					if !(targetStage = nil) and !(targetStage.name = Stage[ctr].name){
						targetStage.guestsList >- self;
						write '(Time ' + time + '): ' + name+": Leaving Stage "+targetStage.name;
						targetStage.actAttribute[6] <- length(targetStage.guestsList)/10;
					}
					targetStage <- Stage[ctr];
					
				}
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

