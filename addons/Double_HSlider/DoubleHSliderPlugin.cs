using Godot;

[Tool]
public partial class DoubleHSliderPlugin : EditorPlugin
{
    public override void _EnterTree()
    {
        // 动态获取脚本路径（假设插件与脚本在同一目录）
        string scriptPath = GetScript().As<Script>().ResourcePath.GetBaseDir().PathJoin("DoubleHSlider.cs");
        var script = GD.Load<Script>(scriptPath);

        // 加载脚本和图标
        scriptPath = GetScript().As<Script>().ResourcePath.GetBaseDir().PathJoin("icon.png");
        var icon = GD.Load<Texture2D>(scriptPath); // 可选
        //var icon = GD.Load<Texture2D>("res://addons/Double_HSlider/icon.png"); // 可选

        // 关键：注册为 Range 类型，Godot 会自动归类到 Slider 下
        AddCustomType("DoubleSlider", "Range", script, icon);
    }

    public override void _ExitTree()
    {
        RemoveCustomType("DoubleSlider");
    }
}