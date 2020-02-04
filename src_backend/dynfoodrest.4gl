IMPORT security
IMPORT util
IMPORT FGL menuData
IMPORT FGL debug
&include "../src/menus.inc"
DEFINE m_users DYNAMIC ARRAY OF userRecord
--------------------------------------------------------------------------------
#+ GET <server>/dynFoodRest/getToken/id/pwd
#+ result: A Record that contains uesr information
PUBLIC FUNCTION getToken(l_id CHAR(6) ATTRIBUTE(WSParam), l_pwd STRING ATTRIBUTE(WSParam)) ATTRIBUTES( 
		WSPath = "/getToken/{l_id}/{l_pwd}", 
		WSGet,
		WSDescription = "Validate User and get Token")
	RETURNS (userRecord ATTRIBUTES(WSMedia = 'application/json'))
	DEFINE x SMALLINT
	DEFINE l_rec userRecord = (
    user_id: "ERROR", 
		user_name: "Invalid User Id!" )

--TODO: validate the password
	IF m_users.getLength() = 0 THEN
		CALL getUsers()
	END IF
	IF l_pwd != C_APIPASS THEN
		CALL debug.output(SFMT("getToken: User:%1 API:%2 Invalid APIPASS",l_rec.user_id, l_pwd), FALSE)
		RETURN l_rec.*
	END IF
	FOR x = 1 TO m_users.getLength()
		IF l_id = m_users[x].user_id THEN
			LET l_rec.* = m_users[x].*
			LET l_rec.user_token = security.RandomGenerator.CreateUUIDString()
			LET l_rec.token_ts = CURRENT
		END IF
	END FOR
	CALL updateUsers()
	CALL debug.output(SFMT("getToken: %1 %2",l_rec.user_id, l_rec.user_token), FALSE)
	RETURN l_rec.*
END FUNCTION
--------------------------------------------------------------------------------
#+ GET <server>/dynFoodRest/getMenus
#+ result: A Record that contains an Array
PUBLIC FUNCTION getMenus() ATTRIBUTES( 
		WSPath = "/getMenus", 
		WSGet, 
		WSDescription = "Get list of Menus")
	RETURNS (menuList ATTRIBUTES(WSMedia = 'application/json'))

	DEFINE l_menu menuData
	IF NOT l_menu.getMenuList(FALSE) THEN
	END IF
	CALL debug.output(SFMT("getMenus items: %1",l_menu.menuList.rows), FALSE)
	RETURN l_menu.menuList.*
END FUNCTION
--------------------------------------------------------------------------------
#+ GET <server>/dynFoodRest/getMenu/<id>
#+ result: A menu array by ID
PUBLIC FUNCTION getMenu(l_id VARCHAR(6) ATTRIBUTE(WSParam)) ATTRIBUTES( 
		WSPath = "/getMenu/{l_id}", 
		WSGet, 
		WSDescription = "Get a Menu")
	RETURNS (MenuRecord ATTRIBUTES(WSMedia = 'application/json'))
	DEFINE l_menu menuData
	IF NOT l_menu.load(l_id, FALSE) THEN
		LET l_menu.menuData.menu_id = "Invalid MenuID!"
		LET l_menu.menuData.rows = 0
	END IF
	CALL debug.output(SFMT("getMenu id: %1 Items: %2",l_id, l_menu.menuData.rows), FALSE)
	RETURN l_menu.menuData.*
END FUNCTION
--------------------------------------------------------------------------------
#+ POST <server>/dynFoodRest/placeOrder
#+ result: String
PUBLIC FUNCTION placeOrder(l_order orderRecord) ATTRIBUTES( 
		WSPath = "/placeOrder", 
		WSPost, 
		WSDescription = "Place an Order")
	RETURNS (INT,STRING ATTRIBUTES(WSMedia = 'application/json'))

	DISPLAY l_order.*

-- TODO: validate that the token is valid.
	IF STATUS != 0 THEN
		RETURN 100,"Invalid Token!"
	END IF
--TODO: store order
	IF STATUS != 0 THEN
		RETURN 101,"Failed to place order!"
	END IF
	RETURN 0,"Okay"
END FUNCTION
--------------------------------------------------------------------------------
PRIVATE FUNCTION getUsers()
	DEFINE l_json TEXT
	LOCATE l_json IN FILE "users.json"
	CALL util.JSON.parse(l_json, m_users)
END FUNCTION
--------------------------------------------------------------------------------
PRIVATE FUNCTION updateUsers()
	DEFINE l_json TEXT
	LOCATE l_json IN FILE "users.json"
	LET l_json = util.JSON.stringify(m_users)
END FUNCTION
--------------------------------------------------------------------------------