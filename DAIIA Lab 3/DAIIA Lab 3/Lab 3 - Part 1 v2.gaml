/**
* Name: NewModel
* Based on the internal empty template. 
* Author: Abel Valko, Kishore Kumar
* Tags: 
*/

model NQueens

global {
	int numberOfQueens <- 12;
	int counter <- -1;
	int queen0Start <- 0;
	init {
		create Queen number:numberOfQueens;
		loop q from:0 to:numberOfQueens-1 {
			Queen queen <- Queen[q];
			queen.location <- Board[0,q].location;
			queen.row <- q;
			queen.column <-0; 
			queen.ID <- q;
			if q >= 1 {
				queen.predecessor <- Queen[q-1];
			}
			if q < numberOfQueens-1 {
				queen.successor <- Queen[q+1];
			}
			if q = 0 {
				ask queen {
					do initiate;
				}
				queen.column <- queen0Start;
				queen.location <- Board[queen0Start,q].location;
			}
		}
	}
	reflex subLoop {
		counter <- (counter + 1) mod numberOfQueens;
	}
}

species Queen skills:[fipa]{
	int ID <- nil;
	int row <- nil;
	int column <- nil;
	bool placed <- false; 
	bool conflict <- false;
	Queen predecessor <- nil;
	Queen successor <- nil;
	list<Queen> occupied <- nil;
	int startPos <- 0;
	
	action initiate{
		placed <- true;
		do start_conversation (to::[successor], protocol:: 'fipa-contract-net', performative :: 'inform', contents :: ["place"]);
	}

	action identifyConflict{
		
		//write "Checking for conflict from (" + row + "," + column + ")";
		conflict <- false;

		loop r from:0 to:numberOfQueens-1 {
			if (r != row) {
				ask Board[column, r] {
					myself.occupied <- Queen inside self;
					if !empty(myself.occupied) {
						if myself.occupied[0].placed {
							myself.conflict <- true;
							//write myself.name + " has column conflict at row " + r;
						}
					}
				}
				int diagDist <- abs(row - r);
				if column - diagDist >= 0 {
					ask Board[column-diagDist, r]{
						myself.occupied <- Queen inside self;
						if !empty(myself.occupied) {
							if myself.occupied[0].placed {
								myself.conflict <- true;
								//write myself.name + " has diag conflict at: (" + r + "," + (myself.column-diagDist) + ")";
							}
						}
					}
				}
				if column + diagDist < numberOfQueens {
					ask Board[column+diagDist, r] {
						myself.occupied <- Queen inside self;
						if !empty(myself.occupied) {
							if myself.occupied[0].placed {
								myself.conflict <- true;
								//write myself.name + " has diag conflict at: (" + r + "," + (myself.column+diagDist) + ")";
							}
						}
					}
				}
			}
		}
	}
	
	action makeMove {
		write "Trying to place " + name;
		loop i from:1 to: numberOfQueens {
			column <- (column + 1) mod numberOfQueens; //maybe column <- i?
			do identifyConflict;
			if i = numberOfQueens or column = startPos{
				write "Could not place " + name + ". Sending inform to predecessor.";
				placed <- false;
				if predecessor != nil {
					do start_conversation (to::[predecessor], protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ["conflict"]);
				} else {
					write "BIG ERROR!!!!!!!!!!!!!!!!!!!!!!!!!!!!"; //should never happen
					column <- (column + 1) mod numberOfQueens;
					do identifyConflict;
				}
				break;
			} else if !conflict {
				placed <- true;
				break;
			}
		}
		location <- Board[column, row].location;
		if successor != nil and placed{
			write "Placed " + name + " at column " + column;
			do start_conversation (to::[successor], protocol:: 'fipa-contract-net', performative :: 'inform', contents :: ["place"]);
		}
	}
	
	reflex resolveRequest when:!empty(informs){
		message i <- informs at 0;
		list content <- i.contents;
		write name + " has request: " + content[0];
		if content[0] = 'place' { 	//unnecesary if, legacy
			do makeMove;
			startPos <- column;
		} else if content[0] = 'conflict' {
			do makeMove;
		}
		
		do end_conversation message:i contents:["Understood"];
	}
	
	aspect default {
		if !placed {
			draw circle(1) color:#yellow;
		} else if conflict {
			draw circle(1) color:#red;
		} else {
			draw circle(1) color:#blue;
		}
	}
}

grid Board width:numberOfQueens height:numberOfQueens{
	
}


experiment MyExperiment type:gui{
	output {
		display MyDisplay type:java2D{
			grid Board lines:#black;
			species Queen aspect: default;
		}
	}
}
