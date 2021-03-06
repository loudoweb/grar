package grar.model.contextual;

import haxe.ds.GenericStack;

typedef Entry = {

	var title : String;
	var author : String;
	var editor : String;
	var year : Int;
	var link : String;
	var sumup : String;
	var themes : List<String>;
	var programs : List<String>;
}

/**
 * Glossary will be accessible in all your game to provide books and articles references
 */
class Bibliography {

	public function new(e : Array<Entry>) {

		this.entries = e;
		this.newEntry = (e.length > 0);
	}

	private var entries : Array<Entry>;

	private var newEntry : Bool = false;

	/**
     * Get the entries in the bibliography
     * @param	filter : Filter the entries by any field except year and sumup
     * @return the entries matching the filter or all of them if no filter was given
     */
	public function getEntries( ? filters : GenericStack<String> ) : Array<Entry> {

		if (newEntry) {

			entries.sort(sort);
			newEntry = false;
		}
		if (filters != null) {

			return applyFilter(filters, entries);
		
		} else {

			return entries;
		}
	}

	/**
     * Add an entry to the bibliography
     * @param	entry : Entry to add
     */
	public function addEntry( entry : Entry ) : Void {

		entries.push(entry);
		newEntry = true;
	}

	/**
     * @return all the programs mentionned in the bibliography
     */
	public function getAllPrograms() : GenericStack<String> {

		var list = new GenericStack<String>();

		for (entry in entries) {

			for (prgm in entry.programs) {

				if (!contains(list, prgm)) {

					list.add(prgm);
				}
			}
		}
		return list;
	}


	///
	// Internals
	//

	private function sort(x:Entry, y:Entry)  :Int {

		if (x.author.toLowerCase() < y.author.toLowerCase()) {

			return -1;
		
		} else if(x.author.toLowerCase() > y.author.toLowerCase()) {

			return 1;
		
		} else {

			if (x.title.toLowerCase() < y.title.toLowerCase()) {

				return -1;
			}
			if (x.title.toLowerCase() > y.title.toLowerCase()) {

				return 1;
			}
			return 0;
		}
	}

	private function contains(list : Iterable<String>, value : String) : Bool {

		for (item in list) {

			if (item == value) {

				return true;
			}
		}
		return false;
	}

	private function applyFilter(filters : GenericStack<String>, entries : Iterable<Entry>) : Array<Entry> {

		var result : Array<Entry> = new Array();
		var ereg = new EReg(filters.pop(), "");

		for (entry in entries) {

			if (ereg.match(entry.author.toLowerCase()) || ereg.match(entry.title.toLowerCase()) || ereg.match(entry.editor.toLowerCase())) {

				result.push(entry);
			
			} else {

				for (program in entry.programs) {

					if (ereg.match(program.toLowerCase())) {

						result.push(entry);
						break;
					}
				}
				for (theme in entry.themes) {

					if (ereg.match(theme.toLowerCase())) {

						result.push(entry);
						break;
					}
				}
			}
		}
		if (!filters.isEmpty()) {

			return applyFilter(filters, result);
		
		} else {

			return result;
		}
	}
}