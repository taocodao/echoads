export default function DemoPage() {
  return (
    <div style={{ display: "flex", flexDirection: "column", height: "calc(100vh - 150px)" }}>
      <iframe
        src="/demo/arenza/index.html"
        style={{ width: "100%", height: "100%", border: "none", borderRadius: "12px", background: "#fff" }}
        title="Arenza Demo"
      />
    </div>
  );
}
