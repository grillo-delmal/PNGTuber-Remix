using Godot;

public partial class Test : Control
{
    [Export]
    DoubleHSlider doubleHSlider;
    [Export] Label lowerV, upperV;

    public override void _Ready()
    {
        doubleHSlider.ValueChanged += DoubleSlider_ValueChanged;
    }

    private void DoubleSlider_ValueChanged(float lower, float upper)
    {
        lowerV.Text = lower.ToString();
        upperV.Text = upper.ToString();
    }
}
