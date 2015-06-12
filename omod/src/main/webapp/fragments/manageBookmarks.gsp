<style type="text/css">
	#grouped-functionality {
		float:right;
	}
	
	#selected-bookmark-dialog-content {
		display:none;
	}
	
	.ui-dialog > .ui-widget-header {
		background: #00463f;
		color:white;
	}
	
	.ui-widget-header .ui-icon {
		background-image: url(../scripts/jquery-ui/css/green/images/ui-icons_ffffff_256x240.png);
	}
	
	input[type='textbox'] {
		width:280px;
	}
	
</style>

<script type="text/javascript">
	var allReturnedBookmarks =' ${ allFoundBookmarks }';
    var bookmarksAfterparse = JSON.parse(allReturnedBookmarks).reverse();
	
	jq(document).ready(function() {
		displayExistingBookmarks();
	
		jq("body").on("click", "#bookmarks-section", function() {
			if(event.target.id === "bookmark-check-all") {
				checkOrUnAllOtherCheckBoxesInADiv("#bookmarks-section", "bookmark-check-all");
			}
		});
		
		jq("table").on('mouseenter', 'tr', function(event) {
			if(event.target.localName !== "th") {
				jq(this).css("cursor", "pointer");
				jq(this).css('background', '#F0EAEA');
			}
		}).on('mouseleave', 'tr', function () {
			jq(this).css('background', '');
		});
		
		jq("body").on("click", "#returned-search-bookmarks tr", function(event) {
			if(event.target.localName !== "input" && event.target.localName !== "label" && event.target.id !== "bookmarks-tb-header") {
				var bookmarkUuid = jq(this).attr("id");
				
				invokeBookmarkDetailsDialog(bookmarkUuid);
			}
		});
		
		jq("#delete-selected-bookmarks").click(function(event) {
			deleteAllSelectedBookmarks();
		});
		
		jq("body").on("each", "#dialog-bookmark-categories option:selected", function (event) {
				//categories.push(jq(this).text());
		});
		
		jq("#dialog-bookmark-save").click(function(event) {
			var bookmarkUuid = jq("#dialog-bookmark-uuid").val();
			var bkName = jq("#dialog-bookmark-name").val();
			var phrase = jq("#dialog-bookmark-phrase").val();
			var categories = [];
			jq("#dialog-bookmark-categories option:selected").each(function(event) {
				categories.push(jq(this).text());
			});
			var cats = categories.join(', ');
			
			if(confirm("Are you sure you want to Save Changes?")) {
				saveBookmarkProperties(bookmarkUuid, bkName, phrase, cats);
			}
		});
		
		jq("#dialog-bookmark-delete").click(function(event) {
			var bookmarkUuid = jq("#dialog-bookmark-uuid").val();
			
			if(confirm("Are you sure want to Delete This Bookmark?")) {
				deleteBookmarkInTheDialog(bookmarkUuid);
			}
		});
		
		function invokeBookmarkDetailsDialog(bookmarkUuid) {
			jq('#dialog-bookmark-categories').html("");
			
			if(bookmarkUuid) {
		    	jq.ajax({
					type: "POST",
					url: "${ ui.actionLink('fetchBookmarkDetails') }",
					data: {"uuid":bookmarkUuid},
					dataType: "json",
					success: function(bookmarks) {
						var phrase = bookmarks.searchPhrase;
						var cats = bookmarks.categories;
						var bkName = bookmarks.bookmarkName;
						
						//TODO set dialog element values
						jq("#dialog-bookmark-uuid").val(bookmarkUuid);
						jq("#dialog-bookmark-name").val(bkName);
						jq("#dialog-bookmark-phrase").val(phrase);
						jq.each(cats, function(key, value) {   
							jq('#dialog-bookmark-categories').append(jq("<option></option>").attr("value",key).text(value)); 
						});
						jq('#dialog-bookmark-categories option').prop('selected', true);
						
						invokeDialog("#selected-bookmark-dialog-content", "Editing '" + bkName + "' Bookmark", "450px");
					},
					error: function(e) {
					}
				});
	    	}
	    }
		
		function displayExistingBookmarks() {
			var trBookmarkEntries = "";
			var thBookmarks = "<tr id='bookmarks-tb-header'><th><label><input type='checkbox' id='bookmark-check-all' > Select (PatientId)</label></th><th>Default Search</th><th>Bookmark Name </th><th>Search Phrase</th><th>Categories</th></tr>";
			
			if(bookmarksAfterparse.length != 0) {
				for(i = 0; i < bookmarksAfterparse.length; i++) {
					var bookmark = bookmarksAfterparse[i];
					
					trBookmarkEntries += "<tr id='" + bookmark.uuid + "'><td><label><input type='checkbox' class='bookmark-check' id='" + bookmark.uuid + "' > (" + bookmark.patientId + ")</label></td><td><input name='radiogroup' type='radio'></td><td>" + bookmark.bookmarkName + "</td><td>" + bookmark.searchPhrase + "</td><td>" + bookmark.categories + "</td></tr>";
				}
			}
			
			if(trBookmarkEntries !== "") {
				jq("#returned-search-bookmarks").html(thBookmarks + trBookmarkEntries);
			}
		}
		
		function deleteAllSelectedBookmarks() {
    		var selectedUuids = returnUuidsOfSeletedBookmarks();
    		var deleteConfirmMsg = "Are you sure you want to delete " + selectedUuids.length + " Item(s)!";
    		
    		if(selectedUuids.length !== 0) {
	    		if(confirm(deleteConfirmMsg)) {
	    			jq.ajax({
						type: "POST",
						url: "${ ui.actionLink('deleteSelectedBookmarks') }",
						data: {"selectedUuids":selectedUuids},
						dataType: "json",
						success: function(remainingBookmarks) {
							bookmarksAfterparse = remainingBookmarks.reverse();
							
							displayExistingBookmarks();
						},
						error: function(e) {
						}
					});
	    		} else {
	    			//alert("DELETE Cancelled");
	    		}
    		} else {
    			alert("Select at-least one Bookmark to be deleted!");
    		}
    	}
    	
    	function returnUuidsOfSeletedBookmarks() {
    		var selectedBookmarkUuids = [];
	    	
			jq('#bookmarks-section input:checked').each(function() {
				var selectedId = jq(this).attr("id");
				
				if(selectedId !== "bookmark-check-all" && jq(this).attr("type") !== "radio") {
			    	selectedBookmarkUuids.push(selectedId);
			    }
			});
			return selectedBookmarkUuids;
    	}
    	
    	function saveBookmarkProperties(bookmarkUuid, bkName, phrase, categories) {
    		jq('#selected-bookmark-dialog-content').dialog('close');
    		if(bookmarkUuid !== "" && bkName !== "" && phrase !== "") {
    			jq.ajax({
					type: "POST",
					url: "${ ui.actionLink('saveBookmarkProperties') }",
					data: { "bookmarkUuid":bookmarkUuid, "bookmarkName":bkName, "searchPhrase":phrase, "selectedCategories":categories },
					dataType: "json",
					success: function(remainingBookmarks) {
						bookmarksAfterparse = remainingBookmarks.reverse();
							
						displayExistingBookmarks();
					},
					error: function(e) {
					}
				});
    		}
    	}
    	
    	function deleteBookmarkInTheDialog(bookmarkUuid) {
    		jq('#selected-bookmark-dialog-content').dialog('close');
    		if(bookmarkUuid !== "") {
    			jq.ajax({
					type: "POST",
					url: "${ ui.actionLink('deleteBookmarkInTheDialog') }",
					data: { "bookmarkUuid":bookmarkUuid },
					dataType: "json",
					success: function(remainingBookmarks) {
						bookmarksAfterparse = remainingBookmarks.reverse();
							
						displayExistingBookmarks();
					},
					error: function(e) {
					}
				});
    		}
    	}
		
	});
</script>


<h1>Manage Bookmarks</h1>

<div id="selected-bookmark-dialog-content">
	<input type="hidden" id="dialog-bookmark-uuid" value="">
	Bookmark Name: <input type="textbox" id="dialog-bookmark-name" value=""><br /><br />
	Search Phrase: <input type="textbox" id="dialog-bookmark-phrase" value=""><br /><br />
	Categories: 
		<select multiple id="dialog-bookmark-categories">
		</select> <b>Tip:</b> Use Ctrl + Left Click<br /><br />
	<input type="button" value="Save Changes" id="dialog-bookmark-save" />
	<input type="button" value="Delete This Bookmark" id="dialog-bookmark-delete" />
</div>

<div id="grouped-functionality">
	<input type="button" id="delete-selected-bookmarks" value="Delete Selected"/>
	<input type="button" id="save-default-search" value="Save Default Search"/><br /><br />
</div>

<div id="bookmarks-section">
	<table id="returned-search-bookmarks"></table>
</div>