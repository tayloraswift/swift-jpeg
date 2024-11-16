extension String
{
    public
    static func pad(_ string:String, left count:Int) -> Self
    {
        .init(repeating: " ", count: count - string.count) + string
    }
    public
    static func pad(_ string:String, right count:Int) -> Self
    {
        string + .init(repeating: " ", count: count - string.count)
    }
}
