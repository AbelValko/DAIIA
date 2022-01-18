/**
* Name: NewModel
* Based on the internal empty template. 
* Author: Abel Valko, Kishore Kumar
* Tags: 
*/


model NewModel

/* Insert your model definition here */

global {
		int numberOfParticipants <- 5;
		int numberOfAuctioneers <- 1;
		
		list parts;
		
		init{
			create Auctioneer number:numberOfAuctioneers;
			create Participant number: numberOfParticipants returns: ps;
			
			parts <- ps; //list of all participants
			
			list preferredPrices <- [400, 420, 210, 350, 375]; //Could be randomized, some norm + gaussian deviation
			
			Participant[0].preferredPrice <- preferredPrices[0];
			Participant[1].preferredPrice <- preferredPrices[1];
			Participant[2].preferredPrice <- preferredPrices[2];
			Participant[3].preferredPrice <- preferredPrices[3];
			Participant[4].preferredPrice <- preferredPrices[4];
			
			write 'Simulation started with ' + numberOfParticipants + ' participants and ' + numberOfAuctioneers + ' auctioneers';
		}
		  
}

species Auctioneer skills: [fipa] {
	
	int currentOffer <- 200;
	bool deal <- false;
	string buyer <- nil;
	
	reflex sendRequest when:(time = 1){
		//Sends request to all participants to join auction.	
		write name + ': Starting auction';
			do start_conversation (to::parts, protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['start_auction', 'Merch']);	//Merch hardcoded, contents list format hardcoded	
	}
	
	reflex initiate_cfp when: (time = 2) {
		
		write '(Time ' + time + '): ' + name + ' sends a cfp message to all participants';
		write "Initiating for the price:" + currentOffer;
		do start_conversation (to::parts, protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: ['Propose_price','Merch',currentOffer,buyer]); 			
	}
	
	reflex refusals_handler when: (!empty(refuses) and !deal){
		write '(Time ' + time + '): ' + name + ' received refusals';
		loop r over: refuses{
			write '\t' + name + ' receives a refusal message from ' + agent(r.sender).name + ' with content ' + r.contents ;
			write '\t' + name + ' ends communication with' + agent(r.sender).name ;
			do end_conversation message:r contents: ['See you in the next auction'];
		}
	}
	
	reflex proposals_handler when: (!empty(proposes) and !deal) {
		write '(Time ' + time + '): ' + name + ' received proposals';
		//int counter <- 0;
		if (length(proposes)>1){
			list copy <- proposes;
			loop p over: proposes {
				write '\t' + name + ' receives a proposal message from ' + agent(p.sender).name + ' with content ' + p.contents ;
				list conts <- p.contents;
				float proposedPrice <- conts[1];
				if (proposedPrice > currentOffer){
					currentOffer <- proposedPrice;
					buyer <- agent(p.sender).name;
				}
			}

			loop p over: copy {
				
				do start_conversation (to::p.sender, protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: ['Propose_price','Merch',currentOffer,buyer]);
				
			}
			write '\t'+name+' current bid - best price:'+currentOffer+' bidder:'+buyer;
			write '\t next round of bidding begins';
				//deal <- true;
			}
			
		else if(length(proposes)=1){
			message p<- proposes[0];
			write '\t'+name+' final bid - price:'+currentOffer+' bidder:'+buyer;
			do accept_proposal message: p contents: ['Deal!!'] ;
			
		}
		
		}
}

species Participant skills: [fipa]{
	
	int preferredPrice <- nil;
	int currentOffer <- nil;
		
	reflex receive_inform_messages when: !empty(informs) {
		write '(Time ' + time + '): ' + name + ' receives inform messages';
		
		loop i over: informs {
			write '\t' + name + ' receives a inform message from ' + agent(i.sender).name + ' with content ' + i.contents ;
		}
	}
	
	reflex respond_to_proposals when: !empty(cfps) {
		message proposalFromAuctioneer <- cfps[0];
		list conts <- proposalFromAuctioneer.contents;
		currentOffer <- conts[2];
		string buyerName <- conts[3];
		write '(Time ' + time + '): ' + name + ' receives a cfp message from ' + agent(proposalFromAuctioneer.sender).name + ' with content ' + proposalFromAuctioneer.contents;
		write '\t' + name + ' sends a propose message to ' + agent(proposalFromAuctioneer.sender).name;
		if buyerName = name{
			write 'I am sticking to '+currentOffer;
			do propose message: proposalFromAuctioneer contents: ['Accept',currentOffer] ;
		}
		else{
			if currentOffer < preferredPrice {
		if currentOffer+10 <= preferredPrice{
			write 'I am buying it for '+currentOffer;
			do propose message: proposalFromAuctioneer contents: ['Accept',currentOffer+10] ;
		}
		else {
			write 'I am buying it for '+preferredPrice;
			do propose message: proposalFromAuctioneer contents: ['Accept',preferredPrice] ;
		}		
		} else{
				//write 'I would like to buy it for '+preferredPrice;
			do refuse message: proposalFromAuctioneer contents: ['Reject'] ;
		}
		}
		
		
		

	}
	
	
	reflex receive_accept_proposals when: !empty(accept_proposals) {
		message a <- accept_proposals[0];
		write '(Time ' + time + '): ' + name + ' received an accept_proposal message from ' + agent(a.sender).name + ' with content ' + a.contents;
		
	}
}

experiment MyExperiment {
	
}

