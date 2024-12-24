TOPLEVEL = top_level
VERILOG_FILES = $(TOPLEVEL).v uart.v clkgen48.v sense_module.v latticesense.v decoder.v aes/aes.v aes/keysched.v aes/mixcolumn.v aes/mixcolumns.v aes/rcon.v aes/rotword.v aes/sbox.v aes/shiftrows.v aes/subbytes.v aes/subword.v aes/xtime.v
PCF = LatticeiCE40HX8K.pcf
DEVICE = hx8k
PACKAGE = ct256
YOSYS=yosys
NEXTPNR=nextpnr-ice40
CLOCKS=clocks.py
MHZ=48

all: $(TOPLEVEL).rpt $(TOPLEVEL).bin

synth: $(TOPLEVEL).json

pnr: $(TOPLEVEL).asc

$(TOPLEVEL).json: $(VERILOG_FILES)
	$(YOSYS) -q \
	-L "${TOPLEVEL}_yosys.log" \
	-e 'Driver-driver conflict' \
	-p "hierarchy -top ${TOPLEVEL}" \
	-p "synth_ice40 ${YOSYS_OPTIONS} -json ${TOPLEVEL}.json" \
	$(VERILOG_FILES)
	@cat "${TOPLEVEL}_yosys.log" |grep "Number of cells:"
	@echo "FPGA (HX8K) maximum available number of cells: 7680"

%.asc: %.json $(PCF)
	$(NEXTPNR) -q \
	--$(DEVICE) --package $(PACKAGE) \
	--freq $(MHZ) --ignore-loops \
	-l "${TOPLEVEL}_nextpnr.log" \
	--json $< --pcf $(PCF) --pcf-allow-unconstrained --timing-allow-fail --asc $@
	@cat ${TOPLEVEL}_nextpnr.log  |grep "ICESTORM_LC:"

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

report-info: $(TOPLEVEL).rpt $(TOPLEVEL)_nextpnr.log $(TOPLEVEL)_yosys.log
	@cat ${TOPLEVEL}_yosys.log |grep "Number of cells:"
	@cat ${TOPLEVEL}_nextpnr.log |grep "ICESTORM_LC:"
	@cat ${TOPLEVEL}_icetime.log |grep "Total path delay:"

prog: $(TOPLEVEL).bin $(TOPLEVEL).rpt
	iceprog -S $<

prog-flash: $(TOPLEVEL).bin $(TOPLEVEL).rpt
	iceprog $<

clean:
	rm -f $(TOPLEVEL).blif $(TOPLEVEL).asc $(TOPLEVEL).rpt $(TOPLEVEL).bin $(TOPLEVEL).json $(TOPLEVEL)_*.log

.SECONDARY:
.PHONY: all prog clean
