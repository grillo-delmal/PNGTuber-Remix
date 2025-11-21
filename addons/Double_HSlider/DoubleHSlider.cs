using Godot;
using System;

[Tool]
[GlobalClass]
public partial class DoubleHSlider : Godot.Range
{
    // 私有字段存储实际值
    float _minValue = 0;
    float _maxValue = 10;
    float _step = 0.1f;
    float _lowerValue = 2f;
    float _upperValue = 7f;
    Color _sliderColor = new Color(0.176f, 0.176f, 0.176f);
    Color _rangeColor = new Color(0.2f, 0.6f, 1.0f);
    Color _grabberColor = new Color(0.792f, 0.792f, 0.792f);
    float _grabberSize = 10.0f;
    float _sliderHeight = 4.0f;

    // 覆盖 Range 类的核心属性
    [Export]
    public new float MinValue
    {
        get => _minValue;
        set
        {
            _minValue = AlignToStepPrecise(Mathf.Min(value, MaxValue - Step));
            ClampValues();
            QueueRedraw();
        }
    }

    [Export]
    public new float MaxValue
    {
        get => _maxValue;
        set
        {
            _maxValue = AlignToStepPrecise(Mathf.Max(MinValue + Step, value));
            ClampValues();
            QueueRedraw();
        }
    }

    [Export]
    public new float Step
    {
        get => _step;
        set
        {
            _step = Mathf.Max(0, value); // 确保步长非负
            QueueRedraw();
        }
    }

    // 导出属性（全部通过 set 方法监听变化）
    [Export]
    public float LowerValue
    {
        get => _lowerValue;
        set
        {
            _lowerValue = AlignToStepPrecise(Mathf.Clamp(value, MinValue, UpperValue - Step));
            QueueRedraw(); // 立即刷新
        }
    }

    [Export]
    public float UpperValue
    {
        get => _upperValue;
        set
        {
            _upperValue = AlignToStepPrecise(Mathf.Clamp(value, LowerValue + Step, MaxValue));
            QueueRedraw(); // 立即刷新
        }
    }

    [Export]
    public Color SliderColor
    {
        get => _sliderColor;
        set
        {
            _sliderColor = value;
            QueueRedraw();
        }
    }

    [Export]
    public Color RangeColor
    {
        get => _rangeColor;
        set
        {
            _rangeColor = value;
            QueueRedraw();
        }
    }

    [Export]
    public Color GrabberColor
    {
        get => _grabberColor;
        set
        {
            _grabberColor = value;
            QueueRedraw();
        }
    }

    [Export]
    public float GrabberSize
    {
        get => _grabberSize;
        set
        {
            _grabberSize = Mathf.Max(0, value); // 避免负值
            QueueRedraw();
        }
    }

    [Export]
    public float SliderHeight
    {
        get => _sliderHeight;
        set
        {
            _sliderHeight = Mathf.Max(0, value);
            QueueRedraw();
        }
    }

    // 使用 new 明确隐藏基类事件
    [Signal]
    public new delegate void ValueChangedEventHandler(float lower, float upper);

    private bool _draggingLower = false;
    private bool _draggingUpper = false;

    public override void _Ready()
    {
        // 保证控件最小尺寸
        CustomMinimumSize = new Vector2(200, GrabberSize * 2 + SliderHeight);
        ClampValues();
        QueueRedraw(); // 立即刷新
    }
    public override Vector2 _GetMinimumSize()
    {
        // 明确告知布局系统需要的最小尺寸
        return new Vector2(100, GrabberSize * 2 + SliderHeight);
    }
    public override void _Draw()
    {
        var size = GetRect().Size;
        var sliderY = size.Y / 2;

        // 绘制背景滑块
        DrawRect(new Rect2(0, sliderY - SliderHeight / 2, size.X, SliderHeight), SliderColor);

        // 计算手柄位置
        var lowerPos = GetPositionFromValue(LowerValue, size.X);
        var upperPos = GetPositionFromValue(UpperValue, size.X);

        // 绘制范围
        DrawRect(new Rect2(lowerPos, sliderY - SliderHeight / 2, upperPos - lowerPos, SliderHeight), RangeColor);

        // 绘制手柄
        DrawCircle(new Vector2(lowerPos, sliderY), GrabberSize, GrabberColor);
        DrawCircle(new Vector2(upperPos, sliderY), GrabberSize, GrabberColor);

        // 当两值重合时，绘制特殊样式
        if (LowerValue + Step == UpperValue)
        {
            float posX = GetPositionFromValue(LowerValue, GetRect().Size.X);
            DrawCircle(new Vector2(posX, GetRect().Size.Y / 2), GrabberSize * 1.2f, Colors.Yellow);
        }
    }



    public override void _GuiInput(InputEvent @event)
    {
        if (@event is InputEventMouseButton mouseBtn && mouseBtn.ButtonIndex == MouseButton.Left)
        {
            if (mouseBtn.Pressed)
            {
                // 鼠标按下时检测更近的手柄
                Vector2 mousePos = GetLocalMousePosition();
                float lowerDist = mousePos.DistanceTo(GetGrabberPos(true));
                float upperDist = mousePos.DistanceTo(GetGrabberPos(false));

                _draggingLower = (lowerDist <= upperDist); // 优先拖动距离近的手柄
                _draggingUpper = !_draggingLower;
            }
            else
            {
                _draggingLower = _draggingUpper = false;
            }
        }
        else if (@event is InputEventMouseMotion motion && (_draggingLower || _draggingUpper))
        {
            float newValue = GetValueFromPosition(motion.Position.X, GetRect().Size.X);

            if (_draggingLower)
                LowerValue = Mathf.Min(newValue, UpperValue); // 允许临时等于UpperValue
            else
                UpperValue = Mathf.Max(newValue, LowerValue);

            QueueRedraw();
            EmitSignal(SignalName.ValueChanged, LowerValue, UpperValue);
        }
    }

    private Vector2 GetGrabberPos(bool isLower)
    {
        float posX = GetPositionFromValue(isLower ? LowerValue : UpperValue, GetRect().Size.X);
        return new Vector2(posX, GetRect().Size.Y / 2);
    }

    private float GetPositionFromValue(float value, float width)
    {
        return (value - MinValue) / (MaxValue - MinValue) * width;
    }

    private float GetValueFromPosition(float position, float width)
    {
        var normalized = position / width;
        var value = MinValue + normalized * (MaxValue - MinValue);
        return (value);
    }

    //private float ApplyStep(float value)
    //{
    //    return (int)(Mathf.Round(value / Step)) * Step;
    //}
    // 高精度步长对齐方法（支持任意小数位数）
    private float AlignToStepPrecise(float value)
    {
        if (Step <= 0) return value;

        // 使用decimal进行全精度计算
        decimal decimalStep = (decimal)Step;
        decimal decimalValue = (decimal)value;

        // 计算对齐后的值（四舍五入到最近的步长倍数）
        decimal alignedValue = Math.Round(decimalValue / decimalStep) * decimalStep;

        // 转换为float时控制精度（防止浮点误差）
        return (float)alignedValue;
    }
    private void ClampValues()
    {
        LowerValue = AlignToStepPrecise(Mathf.Clamp(LowerValue, MinValue, MaxValue));
        UpperValue = AlignToStepPrecise(Mathf.Clamp(UpperValue, MinValue, MaxValue));

        if (LowerValue > UpperValue)
        {
            LowerValue = UpperValue;
        }
    }

}